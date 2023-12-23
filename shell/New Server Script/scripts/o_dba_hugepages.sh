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

#Check server name if it's a database server
#Get Location from Server name
case $(hostname | cut -c3-4) in
	db) echo "By it's name it's a database server"
			read -p "Is this correct [yes/no]"
			echo
			case $REPLY in
				[Yy][Ee][Ss]) echo "Continuing on with Setting HugePages";;
				*) echo "Exiting based on your response"
				 exit 1;;
			esac;;
			
	*) echo "By the name it does not appear to be a database server"
		 echo "Exiting..."
		 exit 1;;
esac

##HugePages


#read -p "HugePage Size you want it set to?" varhugepage
varhugepage=4200

#Gotta transform hugepages into actual memory requirements
#Add we are going to add some room for the OS - 4GB (4096)
#varhugemem=$(($varhugepage*2+4096))


#Before we set lets make sure the system has more
#Memory than 4GB

varmem="$(dmidecode -t 17 | grep "Size.*MB" | awk '{s+=$2} END {print s /1024}')"
#varmemMB="$(dmidecode -t 17 | grep "Size.*MB" | awk '{s+=$2} END {print s}')"
if [ $varmem -gt 5 ] ; then
#if [ $varmem -gt 5 ] && [ $varhugemem -lt $varmemMB ] ; then
 echo "We can set this"
else
 echo "Not enough memory - not setting"
 exit 1
fi

echo "Adding settings live"
echo "This script will wait 2 mins before continuing"
echo "If server becomes unresponsive reboot - settings are not persistant yet"

####Drop cache - sync then check 
#Let's add it to see if we blow the server up first
sysctl -w vm.nr_hugepages=$varhugepage
sysctl -w vm.hugetlb_shm_group=2000


#Maybe remove
echo "Waiting for 2 mins to make sure server is okay to proceed"
sleep 2m

echo "Everything seems okay - making change persistant"
#Write the persistant file
#CHECK for overwrite...

cat <<EOF >> /etc/sysctl.d/pages.conf
#Setting required by Oracle software
vm.nr_hugepages=$varhugepage
vm.hugetlb_shm_group=2000
EOF

chmod 644 /etc/sysctl.d/pages.conf
echo "/etc/sysctl.d/pages.conf was created for this request"