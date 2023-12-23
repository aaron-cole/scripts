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

#Check for Script Directory
if [ ! -d ./scripts ]; then
 echo "Unable to find script directory... exiting..."
 exit 1
else
 chmod +x ./scripts/*.sh
fi
 
##################################
#Start of Script
clear
echo "The Following Scripts were found to assist"
echo "In configuring this system."
echo ""

PS3="Use the number to run the script, enter to redisplay menu, or 'stop' to exit: "

select filename in ./scripts/*.sh; do
#leave menu if user says 'stop'
	if [[ "$REPLY" == "stop" ]]; then break; fi

#complain if no file was selected, then ask again		
	if [[ "$filename" == "" ]]; then
		echo "'$REPLY' is not a valid number"
		continue
	fi

#execute script, then ask again for next one
	$filename
	continue
done
