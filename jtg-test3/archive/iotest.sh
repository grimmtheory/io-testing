#!/bin/bash
clear

# Mount Variables
echo -e "" > /tmp/mounts.tmp
MOUNTPOINTS=`mount -l | grep -v rpc | grep -v xvd | grep -v sysfs | grep -v proc | grep -v devpts | grep -v none | grep -v sunrpc | grep -v nfsd | grep -v tmpfs | grep -v boot | grep on | awk '{ print $3 }'`
for a in `echo $MOUNTPOINTS`; do
	echo -ne "$a, " >> /tmp/mounts.tmp
done
MOUNTS=`cat /tmp/mounts.tmp`
MOUNTS=`echo \($MOUNTS\)`
MOUNTS=`echo $MOUNTS | sed -e 's/, )/)/'`
MOUNTS=`echo $MOUNTS | sed -e 's/( /(/'`

# DD Variables
BS="64"
COUNT="1024"
FILESIZE="`echo "$BS*$COUNT/1024" | bc` MB"
BS=`echo $BS K`
BS=`echo $BS | sed -e 's/ //g'`
DDINPUT="/dev/zero"
DDOUTPUT="/dev/null"
DDTMP="/tmp/dd.out.tmp"

# Result Variables
RESULT="/tmp/result.tmp"
touch $RESULT
echo -e "# SOURCE	DEST		DRIVE		TRANSFER	SPEED" > $RESULT
echo -e "#" >> $RESULT

# Name Variables
SHORTNAME=`hostname -s`
LONGNAME=`hostname -f`

echo -e "###############"
echo -e "# BEGIN TESTING"
echo -e "#"
echo -e "# Local Host = $LONGNAME"
echo -e "# Blocksize  = $(echo $BS | sed -e 's/K//g') KB"
echo -e "# Count      = $COUNT"
echo -e "# Filesize   = $FILESIZE"
echo -e "# Input      = $DDINPUT"
echo -e "# Output     = $DDOUTPUT"
echo -e "# Mounts     = $MOUNTS"
echo -e "#"

for MOUNT in $MOUNTPOINTS; do
	MOUNTDEVICE=`mount -l | grep " $MOUNT " | awk '{ print $1 }'`
	echo -e "########################################"
	echo -e "#"
	echo -e "# REMOTE       = $MOUNTDEVICE"
	echo -e "# LOCAL        = $MOUNT"

	DDOUT=$((time sh -c "dd if=$DDINPUT of=$MOUNT/dd.tmp bs=$BS count=$COUNT oflag=direct") 2>&1)
	echo "$DDOUT" > $DDTMP
	WRITESPEED=`cat $DDTMP | grep copied | awk '{ print $8 " " $9 }'`
	WRITEDATASIZE=`ls -lh $MOUNT/dd.tmp | grep dd.tmp | awk '{ print $5 }'`

	DDOUT=$((time sh -c "dd if=$MOUNT/dd.tmp of=$DDOUTPUT bs=$BS count=$COUNT iflag=direct conv=fdatasync") 2>&1)
	echo "$DDOUT" > $DDTMP
	READSPEED=`cat $DDTMP | grep copied | awk '{ print $8 " " $9 }'`
	READDATASIZE=`ls -lh $MOUNT/dd.tmp | grep dd.tmp | awk '{ print $5 }'`

	AVGREADSPEED=`echo $READSPEED | awk '{ print $1 }'`
	AVGWRITESPEED=`echo $WRITESPEED | awk '{ print $1 }'`
	AVGSPEED=`echo "scale=1;($AVGREADSPEED+$AVGWRITESPEED)/2" | bc`
	
	rm -rf $MOUNT/dd.tmp
	echo -e "# DATA SIZE    = $WRITEDATASIZE"
	echo -e "#"
	echo -e "# DATA SOURCE  = $DDINPUT"
	echo -e "# DATA DEST    = $MOUNT/dd.tmp..."
	echo -e "# WRITE SPEED  = $WRITESPEED"
	echo -e "#"
	echo -e "# DATA SOURCE  = $MOUNT/dd.tmp..."
	echo -e "# DATA DEST    = $DDOUTPUT"
	echo -e "# READ SPEED   = $READSPEED"
	echo -e "#"
	echo -e "# AVERAGE      = $AVGSPEED (50% read / 50% write)"
	echo -e "#"
	echo -e "#"

	DEST=`echo $MOUNT | awk -F\- '{ print $3 }'`
	DRIVE=`echo $MOUNT | awk -F\- '{ print $2 }' | sed -e 's/drive//g'`
	echo -e "# jtg-$DEST	$SHORTNAME	$DRIVE		READ		$READSPEED" >> $RESULT
	echo -e "# $SHORTNAME	jtg-$DEST	$DRIVE		WRITE		$WRITESPEED" >> $RESULT
	echo -e "# 						AVG		$AVGSPEED MB/s" >> $RESULT
	echo -e "#" >> $RESULT
done

echo -e "########################################"
echo -e "#"
echo -e "# END TESTING - RESULTS"
echo -e "#"
cat $RESULT
echo -e "########################################"
