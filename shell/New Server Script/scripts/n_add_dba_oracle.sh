#!/bin/bash

#Check if running as root
if [ "$(id -u)" != "0" ]; then
	echo "This has to be run as root" 1>&2
	exit 1
fi

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


#Creating dba group
if ! grep "^dba:x:2000" /etc/group; then
 groupadd -g 2000 dba
fi

if [ $? -eq 0 ]; then
 echo "dba group created"
else
 echo "Failed creating group"
 exit 2
fi

if ! grep "^oracle:x:2000" /etc/passwd; then
 useradd -g 2000 -u 2000 -c "Oracle Account" -s /bin/sh -m oracle
 if [ $? -ne 0 ]; then
	echo "Failed to add oracle account - exiting"
 exit 2
 fi
 
 chage -M 365 oracle
 
 echo "We got to change the Oracle account Password"
 newpass="$(date +%s | sha256sum | base64 | head -c 32; echo)"
 echo "$newpass" | passwd --stdin oracle
fi

if [ $? -eq 0 ]; then
 echo "oracle account created"
else
 echo "Failed creating oracle account"
fi

echo "Adding some default entries to /etc/sysctl.d/pages for Oracle"
echo ""
cat <<EOF > /etc/sysctl.d/pages.conf
# items for Oracle 12
net.core.rmem_default=4194304
net.core.wmem_default=4194304
net.core.rmem_max=4194304
net.core.wmem_max=4194304
kernel.sem=500 32000 250 1024
fs.file-max=6815744
fs.aio-max-nr=1048576
EOF

echo "Adding oracle to /etc/cron.allow"
echo ""
echo "oracle" >> /etc/cron.allow

echo "Adding Entries for oracle to /etc/security/limits.d/oracle.con"
echo ""
cat <<EOF > /etc/security/limits.d/oracle.conf
oracle              soft    nproc   16384
oracle              hard    nproc   16384
oracle              soft    nofile  4096
oracle              hard    nofile  65536
oracle              soft    stack   10240
oracle              soft    memlock unlimited
oracle              hard    memlock unlimited
EOF