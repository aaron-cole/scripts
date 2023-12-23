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

#Get Location from Server name
echo "Setting logserver Server based on hostname"

case $(hostname | cut -c1-2) in
	rh|ho|lo)  NEWLINE="*.info;mail.none;cron.none;authpriv.notice\t\t@loggserver1.localhost";;

	*) echo "ensure the hostname is set properly to use this script"
		 echo "exiting, because we do not know...."
		 exit 1;;		 
esac

#Lets see if we find a current ACTIVE logserver line 
if [ $(grep -v "^#" /etc/rsyslog.conf | grep "@" | wc -l) -eq 1 ]; then 
#We found only 1 - so lets just edit it
 OLDLINE="$(grep -v "^#" /etc/rsyslog.conf | grep "@")"
 sed -i "s/$OLDLINE/$NEWLINE/" /etc/rsyslog.conf

elif [ $(grep -v "^#" /etc/rsyslog.conf | grep "@" | wc -l) -gt 1 ]; then
#We found more than 1 - delete them all
#And add ours back in after
#The regular /var/log/messages line
 sed -i -e '/^[^#]*@10*/d' /etc/rsyslog.conf
 sed -i "/^[^#]*\/var\/log\/messages/{s/.*/&\n$NEWLINE/;:a;n;ba}" /etc/rsyslog.conf
	
else
#We didn't find anything so lets just
#add it in
 sed -i "/^[^#]*\/var\/log\/messages/{s/.*/&\n$NEWLINE/;:a;n;ba}" /etc/rsyslog.conf

fi
echo ""
echo "Finish Editing /etc/rsyslog.conf"
echo "Restarting services to take effect"

#Restarting services
case $OS in
 	 RHEL6) service rsyslog restart;;
 	 				
	 RHEL7) systemctl restart rsyslog;;		
	 				
esac
echo ""
echo "---------------------------------------"
echo ""
