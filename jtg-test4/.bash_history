exit
passwd
ssh-keygen 
vim /etc/resolv.conf 
vim /etc/hosts
cat .ssh/id_rsa.pub 
ifconfig
vim /etc/fstab 
mkdir /mnt/jtg-test3
mount -a
yum -y install nfs nfs-utils nfs-lib
mount -a
vim /etc/fstab 
mount -a
vim /etc/fstab 
mount -a
vim /etc/fstab 
mount -a
mkdir /mnt/ossn01
mount -a
chkconfig iptables off
/etc/init.d/iptables stop
mount -a
mount -l
cat /etc/fstab 
mount -a
mount -t nfs 129.74.246.249:/data/grimm /mnt/ossn01
mount -t nfs 162.242.168.146:/home/nfstest /mnt/jtg-test3/
showmount -e 162.242.168.146
/etc/init.d/rpcbind status
chkconfig rpcbind on
/etc/init.d/rpcbind start
showmount -e 162.242.168.146
showmount -e 162.242.168.156
ping jtg-test3
ping 129.74.246.249
showmount -h
showmount --all 129.74.246.249
showmount -e 129.74.246.249
showmount -e 162.242.168.156
/etc/init.d/nfs status
chkconfig nfs on
/etc/init.d/nfs restart
showmount -e 162.242.168.156
showmount -e 162.242.168.146
chkconfig iptables off
/etc/init.d/iptables stop
showmount -e 162.242.168.146
showmount -e 129.74.246.249
vim /etc/fstab 
mount -a
mount -l
scp jtg-test3:/root/*.sh .
cp nd-iotest.sh local-iotest.sh
vim local-iotest.sh
./local-iotest.sh 
yum -y install mutt
vim /tmp/result.csv 
vim local-iotest.sh 
./local-iotest.sh 
cat /tmp/result.csv 
vim local-iotest.sh 
echo -e \t a
echo -e /t a
echo -e "\t a"
man cat
cat /etc/fstab 
vim /etc/fstab
mount -l
umount /mnt/jtg-test3/
mount -a
exit
ls -lah
mount -l
cat /etc/fstab 
vim /etc/fstab 
mount -a
vim /etc/fstab 
mount -a
mount -l
scp jtg-test3:/root/*.sh .
ls -lah
vim nd-iotest.sh 
./nd-iotest.sh 
scp jtg-test3:/root/*ctl* .
scp jtg-test3:/etc/sysctl.conf /etc/sysctl.conf 
sysctl -p
sysctl -a
ssh jtg-test3
top
mount -l
umount /mnt/jtg-test3/
vim /etc/fstab 
mount -a
mount -l
vim nd-iotest.sh 
./nd-iotest.sh 
vim nd-iotest.sh 
./nd-iotest.sh 
date +%A-%B-%w-%Y--%H:%M
date +%A-%B-%w-%Y--%H:%M:%S
tail -f /tmp/result.csv 
ssh jtg-test3
mount -l
./nd-iotest.sh 
mount -l
vim /etc/fstab 
umount /mnt/ossn01/
mount -l
mount -a
mount -l
vim /etc/fstab 
umount /mnt/ossn01/
mount -l
mount -a
mount -l
clear
./nd-iotest.sh 
date
ntpdate pool.ntp.org
date
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
date
clear
./nd-iotest.sh 
ssh jtg-test3 "/root/nd-iotest.sh &" && ./nd-iotest.sh &
ls
./nd-iotest.sh 
ls -lah /mnt/ossn01/
date
cat /mnt/ossn01/result.csv 
mount -l
cat /etc/sysctl.conf 
sysctl -p
pwd
ls
./nd-iotest.sh 
cd /mnt/ossn01/
ls
cat result.csv | wc -l
watch cat result.csv | wc -l
watch "cat result.csv | wc -l"
mutt
cd
tail nd-iotest.sh 
ls
scp sysctl.conf.test jtg-test3:/var/www/html/ndrax
scp jtg-test3:/etc/sysctl.conf /etc/sysctl.conf
sysctl -p
vim nd-iotest.sh 
./nd-iotest.sh 
vim nd-iotest.sh 
scp /root/*.sh jtg-test3:/var/www/html/ndrax/archive
./nd-iotest.sh 
man scp
vim nd-iotest.sh 
cat nd-iotest.sh 
echo "New NFS test results attached from $SHORTNAME - $(date +%A-%d-%w-%Y--%H:%M:%S)" | mutt -s "New NFS test results attached from $SHORTNAME - $(date +%A-%B-%d-%Y--%H:%M:%S)" jason.grimm@rackspace.com
mail
mutt
ls
cd Mail
count=0; while [ $count -lt 10 ]; do echo "Pass # $count"; /root/nd-iotest.sh; let count=$count+1; done
cd ..
scp nd-iotest.sh jtg-test3:/root
vim nd-iotest.sh 
scp nd-iotest.sh jtg-test3:/root
count=0; while [ $count -lt 10 ]; do echo "Pass # $count"; /root/nd-iotest.sh; let count=$count+1; done
grep sort nd-iotest.sh 
cp nd-iotest.sh nd-iotest-write.sh
cp nd-iotest.sh nd-iotest-read.sh
vim nd-iotest-read.sh 
sed -i -e 's/WRITE/READ/g' nd-iotest-read.sh 
vim nd-iotest-read.sh
./nd-iotest-read.sh 
ls -lah /mnt/ossn01/
vim nd-iotest-read.sh
ls -lah /tmp/
vim nd-iotest-read.sh
./nd-iotest-read.sh 
ls -lah /mnt/ossn01/
vim nd-iotest-read.sh 
./nd-iotest-read.sh 
ls -lah /mnt/ossn01/
vim nd-iotest-read.sh 
./nd-iotest-read.sh 
ls /tmp/
ls -lah /tmp
vim nd-iotest-read.sh 
./nd-iotest-read.sh 
ls -lah /mnt/ossn01/
bash -x nd-iotest-read.sh 
vim nd-iotest-read.sh 
./nd-iotest-read.sh 
grep dd nd-iotest-read.sh 
dd if=/tmp/jtg-test4-500.mb.file of=/mnt/ossn01/jtg-test4-500.mb.file bs=1048576 count=500
dd if=/tmp/jtg-test4-500.mb.file of=/mnt/ossn01/jtg-test4-500.mb.file bs=1024000 count=500
DDOUT=$((time sh -c "dd if=/tmp/jtg-test4-500.mb.file of=/mnt/ossn01/jtg-test4-500.mb.file bs=1024000 count=500") 2>&1)
ls -lah /mnt/ossn01/
vim nd-iotest-read.sh 
./nd-iotest-read.sh 
ls -lah /mnt/ossn01/
vim nd-iotest-read.sh 
./nd-iotest-read.sh 
vim nd-iotest-tmp.sh
chmod +x nd-iotest-tmp.sh 
./nd-iotest-tmp.sh 
exit
