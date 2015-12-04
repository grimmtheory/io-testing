#!/bin/bash
clear
rm -rf /tmp/*

# Mount Variables
echo -e "" > /tmp/mounts.tmp
MOUNTPOINTS=`mount -l | grep -v '(tmp\|rpc\|xvd\|sysfs\|proc\|devpts\|none\|sunrpc\|nfsd\|tmpfs\|boot\|on)' | awk '{ print $3 }'`
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
ARRSIZE=(500)
ARRBS=(2048 2048 2048 2048 2048 2048 2048)
DDTMP="/tmp/dd.out.tmp"
DDOUTPUT="/dev/null"
DDINPUT="/dev/urandom"
# DDINPUT="/dev/zero"
BLOCKSIZES=`for i in ${ARRBS[*]}; do echo -e -n "($i KB) " ; done`
FILESIZES=`for i in ${ARRSIZE[*]}; do echo -e -n "($i MB) " ; done`
# WRITEFLAG="oflag=direct"
# READFLAG="iflag=direct conv=fdatasync"
WRITEFLAG=""
READFLAG=""

# Result Variables
NOW=`echo $(date +%A-%B-%w-%Y--%H:%M:%S) EST`
RESULTTOP="/tmp/resulttop.txt"
RESULTBOTTOM="/tmp/resultbottom.txt"
RESULTTXT="/tmp/result.txt"
RESULTCSV="/tmp/result.csv"
touch $RESULTTOP; echo "" > $RESULTTOP
touch $RESULTBOTTOM; echo "" > $RESULTBOTTOM
touch $RESULTCSV; echo "" > $RESULTCSV
echo -e "# SOURCE		DEST		DRIVE			TRANSFER	SPEED" > $RESULTBOTTOM
echo -e "#" >> $RESULTBOTTOM
SCRIPT="/root/nd-iotest.sh"

echo -e "" > $RESULTCSV
echo -e "REPORT DATE,$NOW" >> $RESULTCSV
echo -e "FILE SIZES TESTED,$FILESIZES" >> $RESULTCSV
echo -e "BLOCK SIZES TESTED,$BLOCKSIZES" >> $RESULTCSV
echo -e "DD READ FLAGS SET,`if [ "$READFLAG" == "" ]; then echo "NONE"; else echo $READFLAG; fi`" >> $RESULTCSV
echo -e "DD WRITE FLAGS SET,`if [ "$WRITEFLAG" == "" ]; then echo "NONE"; else echo $WRITEFLAG; fi`" >> $RESULTCSV
# echo -e "NFS MOUNT OPTIONS SET,$MOUNTOPTS" >> $RESULTCSV
echo -e "" >> $RESULTCSV
echo -e "DATE,SOURCE,DEST,FILESIZE,BLOCKSIZE,DIRECTION,SPEED (MB/s),SPEED (Mbps),% of Peak" >> $RESULTCSV

# Name Variables
SHORTNAME=`hostname -s`
LONGNAME=`hostname -f`
REMOTEHOST=`mount -l | grep : | awk -F\: '{ print $1 }'`

# Begin
echo -e "########################################" | tee -a $RESULTTOP
echo -e "#" | tee -a $RESULTTOP
echo -e "# TEST PARAMATERS" | tee -a $RESULTTOP
echo -e "#" | tee -a $RESULTTOP
echo -e "# Local Host                = $LONGNAME" | tee -a $RESULTTOP
echo -e "# Remote Host               = $REMOTEHOST" | tee -a $RESULTTOP
echo -e "# Blocksize(s)              = $BLOCKSIZES" | tee -a $RESULTTOP
echo -e "# Filesize(s)               = $FILESIZES" | tee -a $RESULTTOP
echo -e "# Input (write to remote)   = $DDINPUT" | tee -a $RESULTTOP
echo -e "# Output (read from remote) = $DDOUTPUT" | tee -a $RESULTTOP
echo -e "# Mounts                    = $MOUNTS" | tee -a $RESULTTOP
echo -e "#" | tee -a $RESULTTOP
echo -e "########################################" | tee -a $RESULTTOP
echo -e "#" | tee -a $RESULTTOP
echo -e "# GENERATING RANDOM FILES" | tee -a $RESULTTOP
echo -e "#" | tee -a $RESULTTOP

for COUNT in `echo ${ARRSIZE[*]}`; do
	head -c 10m < $DDINPUT > /tmp/seed
	SEED=/tmp/seed
	FILENAME="/tmp/$SHORTNAME-$COUNT.mb.file"
	echo -e -n "# Generating $COUNT MB random file..." | tee -a $RESULTTOP
	echo "for i in {1..$(($COUNT/10))}; do cat $SEED >> $FILENAME; done" > /tmp/test.sh
	chmod +x /tmp/test.sh; /tmp/test.sh
	echo -e "DONE" | tee -a $RESULTTOP
	echo -e "#" | tee -a $RESULTTOP
done

echo -e "########################################" | tee -a $RESULTTOP
echo -e "#" | tee -a $RESULTTOP
echo -e "# BEGIN DATA TRANSFER TESTING" | tee -a $RESULTTOP
echo -e "#" | tee -a $RESULTTOP

for MOUNT in $MOUNTPOINTS; do
	MOUNTDEVICE=`mount -l | grep " $MOUNT " | awk '{ print $1 }'`
	MOUNTOPTS=`mount -l | grep $MOUNT | awk -F\( '{ print $2 }' | sed -e 's/)//g'`
	echo -e "########################################" | tee -a $RESULTTOP
	echo -e "#" | tee -a $RESULTTOP
	echo -e "# REMOTE        = $MOUNTDEVICE" | tee -a $RESULTTOP
	echo -e "# LOCAL         = $MOUNT" | tee -a $RESULTTOP
	echo -e "# MOUNT OPTIONS = $MOUNTOPTS" | tee -a $RESULTTOP
	echo -e "# TEST TIME     = $(date +%A-%B-%w-%Y--%H:%M:%S)" | tee -a $RESULTTOP

	for COUNT in `echo ${ARRSIZE[*]}`; do
		
		FILENAME="/tmp/$SHORTNAME-$COUNT.mb.file"

		for BSIZE in `echo ${ARRBS[*]}`; do
			BS=`echo "$BSIZE*1024" | bc`
			DDOUT=$((time sh -c "dd if=$FILENAME of=$MOUNT/$SHORTNAME-$COUNT.mb.file bs=$BS count=$COUNT $WRITEFLAG") 2>&1)
			echo "$DDOUT" > $DDTMP
			WRITESPEED=`cat $DDTMP | grep copied | awk '{ print $8 " " $9 }'`
			WRITEDATASIZE=`ls -lh $MOUNT/$SHORTNAME-$COUNT.mb.file | awk '{ print $5 }'`

			DDOUT=$((time sh -c "dd if=$MOUNT/$SHORTNAME-$COUNT.mb.file of=$DDOUTPUT bs=$BS count=$COUNT $READFLAG") 2>&1)
			echo "$DDOUT" > $DDTMP
			READSPEED=`cat $DDTMP | grep copied | awk '{ print $8 " " $9 }'`
			READDATASIZE=`ls -lh $MOUNT/$SHORTNAME-$COUNT.mb.file | awk '{ print $5 }'`

			AVGREADSPEED=`echo $READSPEED | awk '{ print $1 }'`
			AVGWRITESPEED=`echo $WRITESPEED | awk '{ print $1 }'`
			AVGSPEED=`echo "scale=1;($AVGREADSPEED+$AVGWRITESPEED)/2" | bc`
		
			echo -e "#" | tee -a $RESULTTOP
			echo -e "########################################" | tee -a $RESULTTOP
			echo -e "#" | tee -a $RESULTTOP
			echo -e "# TESTING $COUNT MB FILE" | tee -a $RESULTTOP
			echo -e "#" | tee -a $RESULTTOP
			echo -e "# DATA SIZE    = $COUNT MB" | tee -a $RESULTTOP
			echo -e "# BLOCK SIZE   = $BSIZE KB" | tee -a $RESULTTOP
			echo -e "# TEST TIME    = $(date +%A-%B-%w-%Y--%H:%M:%S)" | tee -a $RESULTTOP
			echo -e "#" | tee -a $RESULTTOP
			echo -e "# DATA SOURCE  = $FILENAME" | tee -a $RESULTTOP
			echo -e "# DATA DEST    = $MOUNT/$SHORTNAME-$COUNT.mb.file" | tee -a $RESULTTOP
			echo -e "# WRITE SPEED  = $WRITESPEED" | tee -a $RESULTTOP
			echo -e "#" | tee -a $RESULTTOP
			echo -e "# DATA SOURCE  = $MOUNT/$SHORTNAME-$COUNT.mb.file" | tee -a $RESULTTOP
			echo -e "# DATA DEST    = $DDOUTPUT" | tee -a $RESULTTOP
			echo -e "# READ SPEED   = $READSPEED" | tee -a $RESULTTOP
			echo -e "#" | tee -a $RESULTTOP
			echo -e "# AVERAGE      = $AVGSPEED (50% read / 50% write)" | tee -a $RESULTTOP
			echo -e "#" | tee -a $RESULTTOP

			DRIVE=`echo $MOUNT`
			FILE="$MOUNT/$SHORTNAME-$COUNT.mb.file"
			echo -e "# $REMOTEHOST	$SHORTNAME	$DRIVE		READ		$READSPEED" >> $RESULTBOTTOM
			echo -e "# $SHORTNAME		$REMOTEHOST	$DRIVE		WRITE		$WRITESPEED" >> $RESULTBOTTOM
			echo -e "# 								AVG		$AVGSPEED MB/s" >> $RESULTBOTTOM
			echo -e "#" >> $RESULTBOTTOM

			READmbps=`echo $READSPEED | awk '{ print $1 }'`
			READmbps=`echo "scale=1;($READmbps*8)" | bc`
			READPeak=`echo "scale=2;($READmbps*100/8/100)" | bc`

			WRITEmbps=`echo $WRITESPEED | awk '{ print $1 }'`
			WRITEmbps=`echo "scale=1;($WRITEmbps*8)" | bc`
			WRITEPeak=`echo "scale=2;($WRITEmbps*100/8/100)" | bc`

			AVGmbps=`echo "scale=1;($AVGSPEED*8)" | bc`

			echo -e "$(date +%A-%B-%w-%Y--%H:%M:%S),$SHORTNAME :: $FILENAME,$REMOTEHOST :: $FILE,$COUNT MB,$BSIZE KB,WRITE,$WRITESPEED,$WRITEmbps Mbps,$WRITEPeak %" >> $RESULTCSV
			echo -e "$(date +%A-%B-%w-%Y--%H:%M:%S),$REMOTEHOST :: $FILE,$SHORTNAME :: /dev/null,$COUNT MB,$BSIZE KB,READ,$READSPEED,$READmbps Mbps,$READPeak %" >> $RESULTCSV
			# echo -e ",,,,,AVG,$AVGSPEED MB/s,$AVGmbps Mbps" >> $RESULTCSV
			# echo -e "" >> $RESULTCSV
		done

	done
done

echo -e "########################################" | tee -a $RESULTTOP
echo -e "#" | tee -a $RESULTTOP
echo -e "# END TESTING - RESULTS" | tee -a $RESULTTOP
echo -e "#" | tee -a $RESULTTOP
cat $RESULTBOTTOM
echo -e "#" | tee -a $RESULTTOP
echo -e "########################################" | tee -a $RESULTTOP
echo -e "#" | tee -a $RESULTTOP
echo -e "# EMAILING RESULTS" | tee -a $RESULTTOP
echo -e "#" | tee -a $RESULTTOP
cat $RESULTTOP > $RESULTTXT; cat $RESULTBOTTOM >> $RESULTTXT
echo "New NFS test results attached from $SHORTNAME - $(date +%A-%B-%w-%Y--%H:%M:%S)" | mutt -s "New NFS test results attached from $SHORTNAME - $(date +%A-%B-%w-%Y--%H:%M:%S)" -a $RESULTCSV -a $RESULTTXT -a $SCRIPT -- jason.grimm@rackspace.com,james.thorne@rackspace.com
echo -e "########################################" | tee -a $RESULTTOP

