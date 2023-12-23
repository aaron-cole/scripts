#!/bin/bash

#Check if running as root
if [ "$(id -u)" != "0" ]; then
	echo "This has to be run as root" 1>&2
	exit 1
fi

#Check dba group
if ! grep "^dba:x:2000" /etc/group; then
 echo "dba group not created"
 echo "exiting..."
 exit 2
fi

if ! grep "^oracle:x:2000" /etc/passwd; then
 echo "oracle account not created"
 echo "exiting..."
 exit 2
fi

#Check for Cluster Tools???? if on exit out

#Check server name if it's a database server
#Get Location from Server name
case $(hostname | cut -c3-4) in
	db) echo "By it's name it's a database server"
			read -p "Is this correct [yes/no]"
			echo
			case $REPLY in
				[Yy][Ee][Ss]) echo "Continuing on with dba settings";;
				*) echo "Exiting based on your response"
				 exit 1;;
			esac;;
			
	*) echo "By the name it does not appear to be a database server"
		 echo "Exiting..."
		 exit 1;;
esac

#List Disks
fdisk -l | grep "Disk /dev" | grep -v mapper

#Choose Disk
echo "This appears to be the disk to use for U01 and U02"
fdisk -l | grep "Disk /dev.*: 4" | grep -v mapper

#NON-Available disks
NONAVAIL="$(pvs | awk '{print $1}' | egrep -v "PV" | tr -d '\n' )"

PASS=0
while [ $PASS -eq 0 ]; do
 echo ""
 if [ -z $NONAVAIL ]; then
  fdisk -l | grep "Disk /dev" | grep -v mapper
 else
  fdisk -l | grep "Disk /dev" | grep -v mapper | egrep -v "$NONAVAIL" 
 fi
 read -p 'DISK Name to Use (suggested Above):' U01U02Disk
 if pvs | grep "$U01U02Disk" >> /dev/null; then
  echo "Try Again, disk is already a PV"
 else
  if fdisk -l | grep "Disk $U01U02Disk:" >> /dev/null; then
   echo "We'll use this one.  Hope it's correct"
   PASS=1
  else
   echo "Can't validate correct response"     
  fi
 fi
done


#U01U02Disk="$(fdisk -l | grep "Disk /dev.*: 4" | grep -v mapper | awk '{print $2}' | cut -f1 -d ":")"

echo "Creating PV"
pvcreate $U01U02Disk

if [ $? -ne 0 ]; then
 echo "Didn't create PV exiting..."
 exit 2
else
 pvs $U01U02Disk
fi


echo "Creating Volume Groups"
vgcreate -c n -s 32M VolGroupU01 $U01U02Disk

if [ $? -ne 0 ]; then
 echo "Didn't create VG exiting..."
 exit 2
else
 vgs VolGroupU01
fi

echo "Creating Logical Volume U01 and formating"
lvcreate -n VolGroupU01-U01 -L 100g VolGroupU01 && mkfs -t ext4 /dev/VolGroupU01/VolGroupU01-U01
lvcreate -n VolGroupU01-U02 -L 270g VolGroupU01 && mkfs -t ext4 /dev/VolGroupU01/VolGroupU01-U02

echo "Creating mount points /u01 and /u02"
if [ ! -d /u01 ]; then
 mkdir /u01
fi

if [ ! -d /u02 ]; then
 mkdir /u02
fi

echo "Adding to /etc/fstab"
echo "/dev/VolGroupU01/VolGroupU01-U01      /u01    ext4    defaults        1 2" >> /etc/fstab
echo "/dev/VolGroupU01/VolGroupU01-U02      /u02    ext4    defaults,nosuid        1 2" >> /etc/fstab

mount -a

if [ $? -ne 0 ]; then
 echo "ISSUES - PLEASE CHECK MANUALLY and COMMENT OUT /etc/fstab entries..."
 echo "DO NOT REBOOT"
 exit 2
fi

chown oracle:dba /u01 /u02
chmod 755 /u01 /u02

echo "Creating /etc/oratab"
touch /etc/oratab
chown oracle:dba /etc/oratab
chmod 755 /etc/oratab

#Moving Oracle Home dir
mv /home/oracle /u01/ && usermod -d /u01/oracle oracle




