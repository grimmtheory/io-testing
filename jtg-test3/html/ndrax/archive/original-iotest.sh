#!/bin/bash
clear
echo -e "" > /tmp/mounts.tmp
MOUNTPOINTS=`mount -l | grep -v sysfs | grep -v proc | grep -v devpts | grep -v none | grep -v sunrpc | grep -v nfsd | grep -v tmpfs | grep -v boot | grep on | awk '{ print $3 }'`
for a in `echo $MOUNTPOINTS`; do
	echo -ne "$a, " >> /tmp/mounts.tmp
done
MOUNTS=`cat /tmp/mounts.tmp`
MOUNTS=`echo \($MOUNTS\)`
MOUNTS=`echo $MOUNTS | sed -e 's/, )/)/'`
MOUNTS=`echo $MOUNTS | sed -e 's/( /(/'`
BS="64"
COUNT="1024"
FILESIZE="`echo "1024*10240/1024" | bc`M"
BS=`echo $BS K`
BS=`echo $BS | sed -e 's/ //g'`

DDINPUT="/dev/zero"
DDOUTPUT="/dev/null"
DDTMP="/tmp/dd.out.tmp"

echo -e "#################"
echo -e "# BEGIN TESTING"
echo -e "#"
echo -e "# Host       = `hostname -s`"
echo -e "# Blocksize  = $BS"
echo -e "# Count      = $COUNT"
echo -e "# Filesize   = $FILESIZE"
echo -e "# Input      = $DDINPUT"
echo -e "# Output     = $DDOUTPUT"
echo -e "# Mounts     = $MOUNTS"
echo -e "#"

for MOUNT in $MOUNTPOINTS; do
	MOUNTDEVICE=`mount -l | grep " $MOUNT " | awk '{ print $1 }'`
	echo -e "###################################"
	echo -e "# Testing performance on mount $MOUNT"
	echo -e "# currently mounted on $MOUNTDEVICE"
	echo -e "#"

	DDOUT=$((time sh -c "dd if=$DDINPUT of=$MOUNT\dd.tmp bs=$BS count=$COUNT oflag=direct") 2>&1)
	echo "$DDOUT" > $DDTMP
	WRITESPEED=`cat $DDTMP | grep copied | awk '{ print $8 " " $9 }'`

	DDOUT=$((time sh -c "dd if=$MOUNT\dd.tmp of=$DDOUTPUT bs=$BS count=$COUNT iflag=direct conv=fdatasync") 2>&1)
	echo "$DDOUT" > $DDTMP
	READSPEED=`cat $DDTMP | grep copied | awk '{ print $8 " " $9 }'`

	rm -rf $MOUNT\dd.tmp
	echo -e "# $MOUNT = $WRITESPEED (WRITE)"
	echo -e "# $MOUNT = $READSPEED (READ)"
	echo -e "#"
done

