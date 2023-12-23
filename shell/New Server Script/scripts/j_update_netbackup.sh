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

#Get Domainname
vardomain="$(echo $(hostname) | cut -f 2-7 -d".")"

#Get Location from Server name
case $(hostname | cut -c1-2) in
	rh) varlocation="redhat";;
	ho|lo) varlocation="home";;
	az) varlocation="azure";;
	*) read -p 'Location of Server all lowercase:' varlocation;;
esac

if [ "$varlocation" = "azure" ]; then
 echo "We do not use Netbackup on Azure"
 echo "Removing if it exists..."
 echo ""
 yum -y erase SYMCnbjava SYMCpddea SYMCnbclt SYMCnbjre SYMCnetbp SYMCpddes VRTSnbpck VRTSpbx VRTSnbclt VRTSnbjre VRTSpddea VRTSnbcfg
 echo ""
 echo "Removed NETBACKUP packages, Exiting Now..."
 echo "---------------------------------------"
 echo ""
 exit 2
fi

#Configure Netbackup
echo ""
echo "Configuring Netbackup Client"
sed -i 's/^CLIENT_NAME =.*$/CLIENT_NAME = '"$(hostname)"'/' /usr/openv/netbackup/bp.conf
sed -i '/^SERVER = .*$/d' /usr/openv/netbackup/bp.conf
case $varlocation in
 rh) nbservers="nbserver1.localhost";;
 ho|lo) nbservers="nbserver2.localhost";;
 *) echo "You will have to configure netbackup servers"
 		echo "Location and netbackup servers are unknown";;
esac

for nbserver in $nbservers; do
 sed -i "1i\SERVER = $nbserver" /usr/openv/netbackup/bp.conf
done

/usr/openv/netbackup/bin/nbcertcmd -getCACertificate -server $(head -1 /usr/openv/netbackup/bp.conf | cut -f3 -d " ")
echo "Netbackup client configuration should be done unless otherwise stated"
echo ""

#Restarting services and checking stuff
case $OS in
 	 RHEL6) service netbackup restart && chkconfig netbackup on;;
 	 				
	 RHEL7) systemctl restart netbackup && systemctl enable netbackup;;
	 				
esac

echo "---------------------------------------"
echo ""