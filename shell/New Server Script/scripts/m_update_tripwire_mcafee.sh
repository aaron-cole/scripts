#!/bin/bash

#Check if running as root
if [ "$(id -u)" != "0" ]; then
	echo "This has to be run as root" 1>&2
	exit 1
fi

#Get RHEL OS Version
 if grep "6." /etc/redhat-release >> /dev/null; then
	OS="RHEL6"
 elif grep "7." /etc/redhat-release >> /dev/null; then
	OS="RHEL7"
 else
  echo "Can't Determine OS version... exiting"
 exit 1
fi

#Tripwire/McAfee
#Restarting service
rm -f /usr/local/tripwire/te/agent/data/agent/reg.data

echo "Restarting Tripwire Service...."
case $OS in
 	 RHEL6) service tripwire-axon-agent restart;;
 	 				
	 RHEL7) systemctl restart tripwire-axon-agent;;		
	 				
esac
echo "---Done---"
echo ""

#McAfee Agent
echo "Updating the McAfee Agent now..."
/etc/init.d/cma stop
/opt/McAfee/agent/bin/maconfig -enforce -noguid
/etc/init.d/cma start
echo "---Done---"
echo ""
echo "---------------------------------------"
echo ""