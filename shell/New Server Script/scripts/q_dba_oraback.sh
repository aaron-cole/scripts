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

#Check for Cluster Tools????

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

#Lets do oraback now
#Oraback disk

echo "Lets do the Oraback stuff now..."

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
 read -p 'DISK Name:' vardisk
 if pvs | grep "$vardisk" >> /dev/null; then
  echo "Try Again, disk is already a PV"
 else
  if fdisk -l | grep "Disk $vardisk:" >> /dev/null; then
   echo "We'll use this one.  Hope it's correct"
   PASS=1
  else
   echo "Can't validate correct response"     
  fi
 fi
done

pvcreate $vardisk
vgcreate VolGroupOraback $vardisk
lvcreate -n oraback -l 100%FREE VolGroupOraback && mkfs -t ext4 /dev/VolGroupOraback/oraback

if [ $? -ne 0 ]; then
 echo "Issues AROSE exiting..."
 exit 2
fi

if [ ! -d /oraback ]; then
 mkdir /oraback
fi

echo "Adding to /etc/fstab"
echo "/dev/VolGroupOraback/oraback /oraback      ext4    defaults,nosuid        1 2" >> /etc/fstab

mount -a

if [ $? -ne 0 ]; then
 echo "ISSUES - PLEASE CHECK MANUALLY and COMMENT OUT /etc/fstab entries..."
 echo "DO NOT REBOOT"
 exit 2
fi

chown oracle:dba /oraback
chmod 755 /oraback
