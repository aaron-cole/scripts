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

#Get Interface
PASS=0
while [ $PASS -eq 0 ]; do
 case $(ip addr | grep "^[0-9]:" |grep -v lo | cut -f 2 -d ":" | wc -l) in
 	0) echo "No interface found. exiting..."
 		 exit 2;;
 	1) varipinterface="$(ip addr | grep "^[0-9]:" |grep -v lo | cut -f 2 -d ":" | awk '{print $1}')"
 		 echo "Only 1 interface found - nothing else to be configured"
 		 exit 2;;
 	*) IFPASS=0
 		 while [ $IFPASS -eq 0 ]; do
 		  echo "Multiple interfaces found"
 		  echo ""
 		  #Lets find them all and display them with their IP
 		  foundinterfaces="$(ip addr | grep "^[0-9]:" |grep -v lo| cut -f2 -d: | awk '{print $1}')"
 		  for foundinterface in $foundinterfaces; do 
 		   foundip="$(ip addr show dev $foundinterface | grep "inet " | awk '{print $2}' | awk -F/ '{print $1}')"
 		   echo "$foundinterface - $foundip"
 		  done
 		  echo ""
 		  echo "Not Recommended to configure interfaces with IPs that are listed above"
 		  echo ""
 		  read -p 'Select the Appropriate Interface Name to Configure:' varipinterface
 		  if ip addr | grep "^[0-9]:" |grep -v lo | cut -f 2 -d ":" | awk '{print $1}' | grep "$varipinterface" >>/dev/null ; then
           IFPASS=1
           PASS=1
          else
           echo "Try Again, can't validate what you typed"
          fi
         done;;
 esac
done

#Configure Other Interfaces - mainly used for AZURE

#Get Location from Server name
case $(hostname | cut -c1-2) in
	rh) varlocation="redhat";;
	ho|lo) varlocation="home";;
	az) varlocation="azure";;
	*) read -p 'Location of Server all lowercase:' varlocation;;
esac

#Azure OTHER Interfaces
if [ "$varlocation" = "azure" ]; then
 if [ -e /etc/sysconfig/network-scripts/ifcfg-$varipinterface ]; then
  rm -rf /etc/sysconfig/network-scripts/ifcfg-$varipinterface
 fi
 echo -e "NAME=$varipinterface" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
 echo -e "DEVICE=$varipinterface" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
 echo -e "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
 echo -e "TYPE=Ethernet" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
 echo -e "BOOTPROTO=dhcp" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
 echo -e "PEERDNS=no" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
 echo -e "IPV4_FAILURE_FATAL=no" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
 echo -e "ZONE=public" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface

else #for all none Azure servers

PASS=0
while [ $PASS -eq 0 ]; do
 read -p 'IP Address:' varipaddr

#Check IP
 if ipvalid "$varipaddr"; then
  echo "($varipaddr) is valid"
  PASS=1
 else
  echo "($varipaddr) is not valid"
 fi
done

#Get Netmask
PASS=0
while [ $PASS -eq 0 ]; do
 read -p 'Netmask:' varnetmask

#Check Netmask
 case $varnetmask in
 	255.255.255.0|255.255.255.128|255.255.255.192|255.255.255.224|255.255.255.240|255.255.255.248|255.255.255.252) 
 		echo "Seems to be valid netmask, this will be applied."
 		PASS=1;;																										
 	*) echo "This does not appear to be a valid netmask, please try again";;
 esac
done

#Get Gateway
PASS=0
while [ $PASS -eq 0 ]; do
 read -p 'Gateway:' vargate

#Check Gateway
  if ipvalid "$vargate"; then
  echo "($vargate) Seems to be valid"
  PASS=1
 else
  echo "($vargate) Seems to be invalid"
 fi
done

#Configure Network Interface
#If config file doesn't exist we have to create it
if [ ! -f /etc/sysconfig/network-scripts/ifcfg-$varipinterface ]; then
	echo "DEVICE=$varipinterface" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
	echo "BOOTPROTO=static" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
	echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
	echo "NETMASK=$varnetmask" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
	echo "IPADDR=$varipaddr" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
	echo "GATEWAY=$vargate" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
	echo "PEERDNS=no" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
	echo "NM_CONTROLLED=no" >> /etc/sysconfig/network-scripts/ifcfg-$varipinterface
else
#Otherwise lets edit it if it does exist
 echo "Setting Network Interface"
 sed -i 's/^BOOTPROTO=.*$/BOOTPROTO=static/' /etc/sysconfig/network-scripts/ifcfg-$varipinterface
 sed -i 's/^IPADDR=.*$/IPADDR='"$varipaddr"'/' /etc/sysconfig/network-scripts/ifcfg-$varipinterface
 sed -i 's/^NETMASK=.*$/NETMASK='"$varnetmask"'/' /etc/sysconfig/network-scripts/ifcfg-$varipinterface
 sed -i 's/^ONBOOT=.*$/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-$varipinterface
 sed -i 's/^GATEWAY=.*$/GATEWAY='"$vargate"'/' /etc/sysconfig/network-scripts/ifcfg-$varipinterface
 sed -i 's/^NM_CONTROLLED=.*$/NM_CONTROLLED="no"/' /etc/sysconfig/network-scripts/ifcfg-$varipinterface
 sed -i 's/^PEERDNS=.*$/PEERDNS="no"/' /etc/sysconfig/network-scripts/ifcfg-$varipinterface
fi


fi

chmod 600 /etc/sysconfig/network-scripts/ifcfg-$varipinterface
ifup $varipinterface
echo "Interface Set"
echo ""
echo "Re-Run to configure Additional Interfaces as necessary"
echo ""
echo "---------------------------------------"
