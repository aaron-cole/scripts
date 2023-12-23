#!/bin/bash

#Check if running as root
if [ "$(id -u)" != "0" ]; then
	echo "This has to be run as root" 1>&2
	exit 1
fi

#Get RHEL OS Version
if grep "6\." /etc/redhat-release >> /dev/null; then
 OS="RHEL6"
elif grep "7\." /etc/redhat-release >> /dev/null; then
 OS="RHEL7"
else
 echo "Can't Determine OS version... exiting"
 exit 1
fi

ipvalid() {
#Validate IP Address format and correctness
local  stat=1
if [[ $varipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
 OIFS=$IFS
 IFS='.'
 ip=($varipaddr)
 IFS=$OIFS
 [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
  stat=$?
fi
return $stat
}

#Get Domainname
vardomain="$(echo $(hostname) | cut -f 2-7 -d ".")"

#Get Location from Server name
case $(hostname | cut -c1-2) in
	rh) varlocation="redhat";;
	ho|lo) varlocation="home";;
	az) varlocation="azure";;
	*) read -p 'Location of Server all lowercase:' varlocation;;
esac

echo ""
echo "---------Management Interface---------"
echo "------------Configuration-------------"
echo ""
#Get IP Address
#Gotta Skip Azure since it's DHCP
if [ "$varlocation" != "azure" ]; then 

 PASS=0
 while [ $PASS -eq 0 ]; do
  read -p 'Enter the New IP Address: ' varipaddr

#Check IP
  if ipvalid "$varipaddr"; then
   echo "($varipaddr) is valid"
   PASS=1
  else
   echo "($varipaddr) is not valid. Try Again..."
  fi
 done

#Get Netmask
 PASS=0
 while [ $PASS -eq 0 ]; do
  read -p 'Enter the New Netmask: ' varnetmask

#Check Netmask
  case $varnetmask in
 		255.255.255.0|255.255.255.128|255.255.255.192|255.255.255.224|255.255.255.240|255.255.255.248|255.255.255.252) 
 		 echo "Seems to be valid netmask, this will be applied."
 		 PASS=1;;																										
 		*) echo "($varnetmask) does not appear to be a valid netmask. Try again...";;
  esac
 done

#Get Gateway
 PASS=0
 while [ $PASS -eq 0 ]; do
  read -p 'Enter the New Gateway IP: ' vargate

#Check Gateway
  if ipvalid "$vargate"; then
   echo "($vargate) Seems to be valid"
   PASS=1
  else
   echo "($vargate) Seems to be invalid. Try again..."
  fi
 done

#If it's an Azure we don't do anything with the interfaces
#Because it's DHCP and it's are already connected

#Get Interface
 PASS=0
 while [ $PASS -eq 0 ]; do
  case $(ip addr | grep "^[0-9]:" |grep -v lo | cut -f 2 -d ":" | wc -l) in
 		0)	echo "No interface found. exiting..."
			exit 2;;
 		1) 	echo "Only 1 interface found - we will use this"
			varipinterface="$(ip addr | grep "^[0-9]:" |grep -v lo | cut -f 2 -d ":" | awk '{print $1}')"
			PASS=1;;
 		*) 	IFPASS=0
			while [ $IFPASS -eq 0 ]; do
			 echo "Multiple interfaces found"
			 ip addr | grep "^[0-9]:" |grep -v lo| cut -f2 -d:
			 echo ""
			 read -p 'Interface Name to use: ' varipinterface
			 if ip addr | grep "^[0-9]:" |grep -v lo | cut -f 2 -d ":" | awk '{print $1}' | grep "$varipinterface" >> /dev/null; then
			  IFPASS=1
			  PASS=1
			 else
			  echo "Try Again, can't validate what you typed"
			 fi
			done;;
  esac
 done

#Verfiy we want to make the change
 echo ""
 echo "We are going to apply these settings"
 echo ""
 echo "IP Address to use:	$varipaddr"
 echo "NETMASK to use:		$varnetmask"
 echo "GATEWAY to use:		$vargate"
 echo "NIC to use:			$varipinterface"
 echo ""

#We want a solid answer so we will force
#the user for one
 PASS=0
 while [ $PASS -eq 0 ]; do
  read -p 'Apply the above changes? [y/n]: ' varchoice
  if [ "$varchoice" = "y" ] || [ "$varchoice" = "yes" ]; then
   PASS=1
  elif [ "$varchoice" = "n" ] || [ "$varchoice" = "no" ]; then
   PASS=1
  else
   echo "Please Enter y/yes or n/no"
  fi
 done

 case $varchoice in
	y|Y|[yY][eE][sS])

 echo ""
 echo "Management Interface..."
#Configure Network Interface
#If config file doesn't exist we have to create it
  if [ ! -f /etc/sysconfig/network-scripts/ifcfg-$varipinterface ]; then
   echo "DEVICE=$varipinterface" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
   echo "BOOTPROTO=static" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
   echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
   echo "NETMASK=$varnetmask" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
   echo "IPADDR=$varipaddr" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
   echo "GATEWAY=$vargate" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
   echo "NM_CONTROLLED=no" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
   echo "DEFROUTE=yes" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
  else
#Otherwise lets edit it if it does exist
  echo "Setting Network Interface"
   sed -i 's/^BOOTPROTO=.*$/BOOTPROTO=static/' /etc/sysconfig/network-scripts/ifcfg-$varipinterface
   sed -i 's/^IPADDR=.*$/IPADDR='"$varipaddr"'/' /etc/sysconfig/network-scripts/ifcfg-$varipinterface
   sed -i 's/^NETMASK=.*$/NETMASK='"$varnetmask"'/' /etc/sysconfig/network-scripts/ifcfg-$varipinterface
   sed -i 's/^ONBOOT=.*$/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-$varipinterface
   sed -i 's/^GATEWAY=.*$/GATEWAY='"$vargate"'/' /etc/sysconfig/network-scripts/ifcfg-$varipinterface
   sed -i 's/^NM_CONTROLLED=.*$/NM_CONTROLLED="no"/' /etc/sysconfig/network-scripts/ifcfg-$varipinterface
   sed -i 's/^DEFROUTE=.*$/DEFROUTE="yes"/' /etc/sysconfig/network-scripts/ifcfg-$varipinterface
  fi

  echo "Interface Set"

#Restarting Network
  echo "Configuring Network Services"
#Restart Services
  case $OS in
 	 RHEL6) service network restart ;;
 	 				
 	 RHEL7) systemctl restart network.service ;;
  esac;;
 
 *) echo "Cancled. No Changes have been made."
    exit 2;;
 esac # End of User Choice to apply changes

#Skipped everything above if it's an Azure server
#For Azure Only
else 
 echo ""
 echo "It's an Azure server, so we are just going to test some things..."
 varipaddr="$(ip addr show dev eth0 | grep "inet " | awk '{print $2}' | awk -F/ '{print $1}')"
 vargate="$(ip route show | grep default | awk '{print $3}')"
fi

#Verify
echo ""
echo ""
echo "---------Testing Items Now---------"
TEST=1
TESTSERVERS="localhost $varipaddr 8.8.8.8"
for TESTSERVER in $TESTSERVERS; do
 echo "Pinging $TESTSERVER"
 ping -q -c1 $TESTSERVER 
 echo ""

 case $? in
  0) echo "Ping Succeeded";;
  *) case $TESTSERVER in
 			localhost) echo "Check network service - Ping localhost failed";;
 			$varipaddr) echo "Check to make sure interface is up";;
 			$vargate)
 								  echo "If VM, Get with VM Team to make sure on the right VLAN"
 								  echo "If physical system, check to make sure Gateway is correct"
 								 ;;
 								  
 			8.8.8.8) echo "If VM, Get with VM Team to make sure on the right VLAN"
 											echo "If physical system, check to make sure Gateway is correct";;
 			esac
 esac
 echo ""
done	
echo ""
echo "Done Configuring/Verifing Management IP"
echo ""
echo "---------------------------------------"