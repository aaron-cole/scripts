#!/bin/bash

#Check if running as root
if [ "$(id -u)" != "0" ]; then
	echo "This has to be run as root" 1>&2
	exit 1
fi

echo "---------------------------------------"
echo "/etc/hosts Configuration"
echo ""

#Get Interface
PASS=0
while [ $PASS -eq 0 ]; do
 case $(ip addr | grep "^[0-9]:" |grep -v lo | cut -f 2 -d ":" | wc -l) in
 	0) echo "No interface found. exiting..."
 		 exit 2;;
 	1) varipinterface="$(ip addr | grep "^[0-9]:" |grep -v lo | cut -f 2 -d ":" | awk '{print $1}')"
 		 varipaddr="$(ip addr show $varipinterface | grep "inet " | awk '{print $2}' | awk -F/ '{print $1}')"
 		 echo "Only 1 interface found - we will use this:"
 		 echo " - $varipinterface - $varipaddr"
 		 echo ""
 		 PASS=1;;
 	*) 	IFPASS=0
 		while [ $IFPASS -eq 0 ]; do
 		 echo "Multiple interfaces found"
 		 echo ""
 		 #Lets find them all and display them with their IP
 		 foundinterfaces="$(ip addr | grep "^[0-9]:" |grep -v lo| cut -f2 -d: | awk '{print $1}')"
 		 for foundinterface in $foundinterfaces exit; do 
		  if [ "$foundinterface" != "exit" ]; then
		   foundip="$(ip addr show dev $foundinterface | grep "inet " | awk '{print $2}' | awk -F/ '{print $1}')"
		  else
		   foundip="To exit this script"
 		  fi
		  echo "$foundinterface - $foundip"
 		 done
 		 echo ""
 		 if [[ "$(hostname | cut -c1-2)" = "az" ]]; then
 		  echo "This is an Azure Server...  eth0 is probably the right interface"
 		  echo ""
 		 fi
 		 read -p 'Select the Appropriate Interface Name: ' varipinterface
 		  if ip addr | grep "^[0-9]:" |grep -v lo | cut -f 2 -d ":" | awk '{print $1}' | grep "$varipinterface" >>/dev/null ; then
           IFPASS=1
		   PASS=1
           varipaddr="$(ip addr show dev $varipinterface | grep "inet " | awk '{print $2}' | awk -F/ '{print $1}')"
		   echo "We will use this:"
 		   echo " - $varipinterface - $varipaddr"
 		   echo ""
		  elif [ "$varipinterface" = "exit" ]; then
		   echo "/etc/hosts has not been configured"
		   echo "Exiting...."
		   echo "---------------------------------------"
		   echo ""
		   exit 1
		  else
		   echo ""
           echo "Unable to validate what you typed.  Try Again..."
		   echo ""
          fi
		 done;;
 esac
done

#Configure /etc/hosts
cp /etc/hosts /etc/hosts.backup
echo ""
echo "Erasing /etc/hosts Completely and adding proper necessary entries"
echo "Please wait..."
echo -e "127.0.0.1\tlocalhost.localdomain localhost.localdomain localhost4 localhost4.localdomain4 localhost" > /etc/hosts
echo -e "#::1\tlocalhost localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
echo -e "" >> /etc/hosts
echo -e "$varipaddr\t$(hostname) $(hostname | cut -f 1 -d ".")" >> /etc/hosts
chmod 644 /etc/hosts
echo ""
echo "The updated /etc/hosts is below"
echo ""
cat /etc/hosts
echo ""
echo "Done Configuring /etc/hosts"
echo ""
echo "backup file is /etc/hosts.backup"
echo "---------------------------------------"