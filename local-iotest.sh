#!/bin/bash
clear
rm -rf /tmp/*

# Mount Variables
echo -e "" > /tmp/mounts.tmp
MOUNTPOINTS=`mount -l | grep -v '(rpc\|xvd\|sysfs\|proc\|devpts\|none\|sunrpc\|nfsd\|tmpfs\|boot\|on)' | awk '{ print $3 }'`
for a in `echo $MOUNTPOINTS`; do
	echo -ne "$a, " >> /tmp/mounts.tmp
done

MOUNTS=`cat /tmp/mounts.tmp`
MOUNTS=`echo \($MOUNTS\)`
MOUNTS=`echo $MOUNTS | sed -e 's/, )/)/'`
MOUNTS=`echo $MOUNTS | sed -e 's/( /(/'`

# MOUNTOPTS=`cat /proc/mounts | grep : | awk '{ print $4 }' | sed -e 's/,/ /g'`
MOUNTOPTS=`mount -l | grep : | awk -F\( '{ print $2 }' | sed -e 's/)//g'`

# DD Variables
# ARRSIZE=(10 100 250 500 1000 10000)
# ARRBS=(4 8 16 32 64 128 256 512 1024 2048)
ARRSIZE=(100 250)
ARRBS=(32 64 128)
DDTMP="/tmp/dd.out.tmp"
DDOUTPUT="/dev/null"
DDINPUT="/dev/urandom"
BLOCKSIZES=`for i in ${ARRBS[*]}; do echo -e -n "($i KB) " ; done`
FILESIZES=`for i in ${ARRSIZE[*]}; do echo -e -n "($i MB) " ; done`
# WRITEFLAG="oflag=direct"
# READFLAG="iflag=direct conv=fdatasync"
WRITEFLAG=""
READFLAG=""

# Result Variables
NOW=`echo $(date +%A-%B-%w-%Y--%H:%M) EST`
RESULT="/tmp/result.tmp"
RESULTCSV="/tmp/result.csv"
touch $RESULT
touch $RESULTCSV
echo -e "# SOURCE		DEST		DRIVE			TRANSFER	SPEED" > $RESULT
echo -e "#" >> $RESULT

echo -e "" > $RESULTCSV
echo -e "REPORT DATE,$NOW" >> $RESULTCSV
echo -e "FILE SIZES TESTED,$FILESIZES" >> $RESULTCSV
echo -e "BLOCK SIZES TESTED,$FILESIZES" >> $RESULTCSV
echo -e "DD READ FLAGS SET,`if [ "$READFLAG" == "" ]; then echo "NONE"; else echo $READFLAG; fi`" >> $RESULTCSV
echo -e "DD WRITE FLAGS SET,`if [ "$WRITEFLAG" == "" ]; then echo "NONE"; else echo $WRITEFLAG; fi`" >> $RESULTCSV
# echo -e "NFS MOUNT OPTIONS SET,$MOUNTOPTS" >> $RESULTCSV
echo -e "" >> $RESULTCSV
echo -e "SOURCE,DEST,FILESIZE,BLOCKSIZE,DIRECTION,SPEED (MB/s),SPEED (Mbps),% of Peak" >> $RESULTCSV

# Name Variables
SHORTNAME=`hostname -s`
LONGNAME=`hostname -f`
REMOTEHOST=`mount -l | grep : | awk -F\: '{ print $1 }'`

# Begin
echo -e "########################################"
echo -e "#"
echo -e "# TEST PARAMATERS"
echo -e "#"
echo -e "# Local Host                = $LONGNAME"
echo -e "# Remote Host               = $REMOTEHOST"
echo -e "# Blocksize                 = $BLOCKSIZES"
echo -e "# Filesize(s)               = $FILESIZES"
echo -e "# Input (write to remote)   = $DDINPUT"
echo -e "# Output (read from remote) = $DDOUTPUT"
echo -e "# Mounts                    = $MOUNTS"
echo -e "#"
echo -e "########################################"
echo -e "#"
echo -e "# GENERATING RANDOM FILES"
echo -e "#"

for COUNT in `echo ${ARRSIZE[*]}`; do
	head -c 10m < /dev/urandom > /tmp/seed
	SEED=/tmp/seed
	FILENAME="/tmp/$COUNT.mb.file"
	echo -e -n "# Generating $COUNT MB random file..."
	echo "for i in {1..$(($COUNT/10))}; do cat $SEED >> $FILENAME; done" > /tmp/test.sh
	chmod +x /tmp/test.sh; /tmp/test.sh
	echo -e "DONE"
	echo -e "#"
done

echo -e "########################################"
echo -e "#"
echo -e "# BEGIN DATA TRANSFER TESTING"
echo -e "#"

for MOUNT in $MOUNTPOINTS; do
	MOUNTDEVICE=`mount -l | grep " $MOUNT " | awk '{ print $1 }'`
	MOUNTOPTS=`mount -l | grep $MOUNT | awk -F\( '{ print $2 }' | sed -e 's/)//g'`
	echo -e "########################################"
	echo -e "#"
	echo -e "# REMOTE        = $MOUNTDEVICE"
	echo -e "# LOCAL         = $MOUNT"
	echo -e "# MOUNT OPTIONS = $MOUNTOPTS"

	for COUNT in `echo ${ARRSIZE[*]}`; do
		
		FILENAME="/tmp/$COUNT.mb.file"

		for BSIZE in `echo ${ARRBS[*]}`; do
			BS=`echo "($BSIZE*8)*1024" | bc`
			DDOUT=$((time sh -c "dd if=$FILENAME of=$MOUNT/$COUNT.mb.file bs=$BS count=$COUNT $WRITEFLAG") 2>&1)
			echo "$DDOUT" > $DDTMP
			WRITESPEED=`cat $DDTMP | grep copied | awk '{ print $8 " " $9 }'`
			WRITEDATASIZE=`ls -lh $MOUNT/$COUNT.mb.file | awk '{ print $5 }'`

			DDOUT=$((time sh -c "dd if=$MOUNT/$COUNT.mb.file of=$DDOUTPUT bs=$BS count=$COUNT $READFLAG") 2>&1)
			echo "$DDOUT" > $DDTMP
			READSPEED=`cat $DDTMP | grep copied | awk '{ print $8 " " $9 }'`
			READDATASIZE=`ls -lh $MOUNT/$COUNT.mb.file | awk '{ print $5 }'`

			AVGREADSPEED=`echo $READSPEED | awk '{ print $1 }'`
			AVGWRITESPEED=`echo $WRITESPEED | awk '{ print $1 }'`
			AVGSPEED=`echo "scale=1;($AVGREADSPEED+$AVGWRITESPEED)/2" | bc`
		
			echo -e "#"
			echo -e "########################################"
			echo -e "#"
			echo -e "# TESTING $COUNT MB FILE"
			echo -e "#"
			echo -e "# DATA SIZE    = $(echo $WRITEDATASIZE | sed -e 's/M//g') MB"
			echo -e "# BLOCK SIZE   = $BSIZE KB"
			echo -e "#"
			echo -e "# DATA SOURCE  = $FILENAME"
			echo -e "# DATA DEST    = $MOUNT/$COUNT.mb.file"
			echo -e "# WRITE SPEED  = $WRITESPEED"
			echo -e "#"
			echo -e "# DATA SOURCE  = $MOUNT/$COUNT.mb.file"
			echo -e "# DATA DEST    = $DDOUTPUT"
			echo -e "# READ SPEED   = $READSPEED"
			echo -e "#"
			echo -e "# AVERAGE      = $AVGSPEED (50% read / 50% write)"
			echo -e "#"

			DRIVE=`echo $MOUNT`
			FILE="$MOUNT/$COUNT.mb.file"
			echo -e "# $REMOTEHOST	$SHORTNAME	$DRIVE		READ		$READSPEED" >> $RESULT
			echo -e "# $SHORTNAME		$REMOTEHOST	$DRIVE		WRITE		$WRITESPEED" >> $RESULT
			echo -e "# 								AVG		$AVGSPEED MB/s" >> $RESULT
			echo -e "#" >> $RESULT

			READmbps=`echo $READSPEED | awk '{ print $1 }'`
			READmbps=`echo "scale=1;($READmbps*8)" | bc`
			READPeak=`echo "scale=2;($READmbps*100/8/125)" | bc`

			WRITEmbps=`echo $WRITESPEED | awk '{ print $1 }'`
			WRITEmbps=`echo "scale=1;($WRITEmbps*8)" | bc`
			WRITEPeak=`echo "scale=2;($WRITEmbps*100/8/125)" | bc`

			AVGmbps=`echo "scale=1;($AVGSPEED*8)" | bc`

			echo -e "$SHORTNAME :: $FILENAME,$REMOTEHOST :: $FILE,$COUNT MB,$BSIZE KB,WRITE,$WRITESPEED,$WRITEmbps Mbps,$WRITEPeak %" >> $RESULTCSV
			echo -e "$REMOTEHOST :: $FILE,$SHORTNAME :: /dev/null,$COUNT MB,$BSIZE KB,READ,$READSPEED,$READmbps Mbps,$READPeak %" >> $RESULTCSV
			# echo -e ",,,,,AVG,$AVGSPEED MB/s,$AVGmbps Mbps" >> $RESULTCSV
			# echo -e "" >> $RESULTCSV
		done

	done
done

echo -e "########################################"
echo -e "#"
echo -e "# END TESTING - RESULTS"
echo -e "#"
cat $RESULT
echo "New NFS test results attached - $NOW" | mutt -a $RESULTCSV -s "New NFS test results attached - $NOW" -- jason.grimm@rackspace.com
echo "New NFS test results attached - $NOW" | mutt -a $RESULTCSV -s "New NFS test results attached - $NOW" -- james.thorne@rackspace.com
echo -e "########################################"

