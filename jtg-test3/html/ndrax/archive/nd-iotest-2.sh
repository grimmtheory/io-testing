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
ARRSIZE=(500 500 500)
ARRBS=(1024 2048 2048 2048 2048 2048 4096 4096 8192 8192 16384)
DDTMP="/tmp/dd.out.tmp"
DDOUTPUT="/dev/null"
DDINPUT="/dev/urandom"
# DDINPUT="/dev/zero"
BLOCKSIZES=`for i in ${ARRBS[*]}; do echo -e -n "$i, " ; done`
BLOCKSIZES=`echo $BLOCKSIZES | sed 's/,$//'`
FILESIZES=`for i in ${ARRSIZE[*]}; do echo -e -n "$i, " ; done`
FILESIZES=`echo $FILESIZES | sed 's/,$//'`
# WRITEFLAG="oflag=direct"
# READFLAG="iflag=direct conv=fdatasync"
WRITEFLAG=""
READFLAG=""

# Result Variables
NOW=`date +%D" "%H:%M" EST"`
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
echo -e "FILE SIZES TESTED (MB),$FILESIZES" >> $RESULTCSV
echo -e "BLOCK SIZES TESTED (KB),$BLOCKSIZES" >> $RESULTCSV
echo -e "DD READ FLAGS SET,`if [ "$READFLAG" == "" ]; then echo "NONE"; else echo $READFLAG; fi`" >> $RESULTCSV
echo -e "DD WRITE FLAGS SET,`if [ "$WRITEFLAG" == "" ]; then echo "NONE"; else echo $WRITEFLAG; fi`" >> $RESULTCSV
# echo -e "NFS MOUNT OPTIONS SET,$MOUNTOPTS" >> $RESULTCSV
echo -e "" >> $RESULTCSV
echo -e "START,STOP,RUNTIME,SOURCE,DEST,FILE (MB),BLOCK (KB),DIRECTION,SPEED (MB/s),SPEED (Mbps)" >> $RESULTCSV

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
	rm -rf $MOUNT/*jtg*.file
	echo -e "########################################" | tee -a $RESULTTOP
	echo -e "#" | tee -a $RESULTTOP
	echo -e "# REMOTE        = $MOUNTDEVICE" | tee -a $RESULTTOP
	echo -e "# LOCAL         = $MOUNT" | tee -a $RESULTTOP
	echo -e "# MOUNT OPTIONS = $MOUNTOPTS" | tee -a $RESULTTOP
	echo -e "# TEST TIME     = $(date +%A-%B-%w-%Y--%H:%M:%S)" | tee -a $RESULTTOP

	for COUNT in `echo ${ARRSIZE[*]}`; do
		
		FILENAME="/tmp/$SHORTNAME-$COUNT.mb.file"

		for BSIZE in `echo ${ARRBS[*]}`; do
		
			DRIVE=`echo $MOUNT`
			FILE="$MOUNT/$SHORTNAME-$COUNT.mb.file"
			BS=`echo "$BSIZE*1024" | bc`
			
			START=`date +%T`
			echo -e -n "`date +%T`," >> $RESULTCSV
			
			DDOUT=$((time sh -c "dd if=$FILENAME of=$MOUNT/$SHORTNAME-$COUNT.mb.file bs=$BS count=$COUNT $WRITEFLAG") 2>&1)
			echo "$DDOUT" > $DDTMP
			WRITESPEED=`cat $DDTMP | grep copied | awk '{ print $8 " " $9 }' | awk '{ print $1 }'`
			WRITEDATASIZE=`ls -lh $MOUNT/$SHORTNAME-$COUNT.mb.file | awk '{ print $5 }'`
			
			WRITEmbps=`echo $WRITESPEED | awk '{ print $1 }'`
			WRITEmbps=`echo "scale=2;($WRITEmbps*8)" | bc`
			WRITEPeak=`echo "scale=2;($WRITEmbps*100/125)" | bc`
			
			STOP=`date +%T`
			RUNTIMESEC=`echo "$(date -d $STOP +%s) - $(date -d $START +%s)" | bc`
			# RUNTIMEMIN=`echo "scale=2;($RUNTIMESEC/60)" | bc`
			
			echo -e "$STOP,$RUNTIMESEC,$SHORTNAME,$REMOTEHOST,$COUNT,$BSIZE,WRITE,$WRITESPEED,$WRITEmbps" >> $RESULTCSV

			START=`date +%H:%M:%S`
			echo -e -n "$START," >> $RESULTCSV

			DDOUT=$((time sh -c "dd if=$MOUNT/$SHORTNAME-$COUNT.mb.file of=$DDOUTPUT bs=$BS count=$COUNT $READFLAG") 2>&1)
			echo "$DDOUT" > $DDTMP
			READSPEED=`cat $DDTMP | grep copied | awk '{ print $8 " " $9 }' | awk '{ print $1 }'`
			READDATASIZE=`ls -lh $MOUNT/$SHORTNAME-$COUNT.mb.file | awk '{ print $5 }'`

			READmbps=`echo $READSPEED | awk '{ print $1 }'`
			READmbps=`echo "scale=2;($READmbps*8)" | bc`
			READPeak=`echo "scale=2;($READmbps*100/125)" | bc`

			AVGREADSPEED=`echo $READSPEED | awk '{ print $1 }'`
			AVGWRITESPEED=`echo $WRITESPEED | awk '{ print $1 }'`
			AVGSPEED=`echo "scale=2;($AVGREADSPEED+$AVGWRITESPEED)/2" | bc`
			AVGmbps=`echo "scale=2;($AVGSPEED*8)" | bc`
			AVGPeak=`echo "scale=2;($AVGmbps*100/125)" | bc`
			
			STOP=`date +%H:%M:%S`
			RUNTIMESEC=$(expr $(date -d "$STOP" +%s) - $(date -d "$START" +%s))
			RUNTIMEMIN=`echo "scale=2;($RUNTIMESEC/60)" | bc`
			
			echo -e "$STOP,$RUNTIMESEC,$REMOTEHOST,$SHORTNAME,$COUNT,$BSIZE,READ,$READSPEED,$READmbps" >> $RESULTCSV
			# echo -e ",,,,,,,,AVG,$AVGSPEED,$AVGmbps,$AVGPeak" >> $RESULTCSV
		
			echo -e "#" | tee -a $RESULTTOP
			echo -e "########################################" | tee -a $RESULTTOP
			echo -e "#" | tee -a $RESULTTOP
			echo -e "# TESTING $COUNT MB FILE" | tee -a $RESULTTOP
			echo -e "#" | tee -a $RESULTTOP
			echo -e "# DATA SIZE    = $COUNT MB" | tee -a $RESULTTOP
			echo -e "# BLOCK SIZE   = $BSIZE KB" | tee -a $RESULTTOP
			echo -e "# TEST TIME    = $NOW" | tee -a $RESULTTOP
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

			echo -e "# $SHORTNAME		$REMOTEHOST	$DRIVE		WRITE		$WRITESPEED" >> $RESULTBOTTOM
			echo -e "# $REMOTEHOST	$SHORTNAME	$DRIVE		READ		$READSPEED" >> $RESULTBOTTOM
			echo -e "# 								AVG		$AVGSPEED MB/s" >> $RESULTBOTTOM
			echo -e "#" >> $RESULTBOTTOM

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
cp $RESULTTXT /var/www/html/ndrax/perf-test-results/$(date +%B-%w-%Y--%H.%M.%S)-result.txt
cp $RESULTCSV /var/www/html/ndrax/perf-test-results/$(date +%B-%w-%Y--%H.%M.%S)-result.csv
cp -f /root/*.sh /var/www/html/ndrax/archive
echo "New NFS test results attached from $SHORTNAME - $(date +%A-%B-%w-%Y--%H:%M:%S)" | mutt -s "New NFS test results attached from $SHORTNAME - $(date +%A-%B-%w-%Y--%H:%M:%S)" -a $RESULTCSV -a $RESULTTXT -a $SCRIPT -- jason.grimm@rackspace.com,james.thorne@rackspace.com
echo -e "########################################" | tee -a $RESULTTOP

