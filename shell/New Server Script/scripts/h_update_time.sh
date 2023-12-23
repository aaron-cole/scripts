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

echo ""
echo "Checking TimeZone"
echo ""
#Check Timezone
if date | grep " UTC " >> /dev/null; then
 echo "Time Zone is set at UTC already"
 vartimezone=0
else
 echo "We have to adjust Time Zone to UTC"
 vartimezone=1
fi

echo ""
echo "Checking ntpservers"
echo ""
#Check NTP
ntpservers="ntpserver1.localhost ntpserver2.localhost"
ntpservercount=0
for ntpserver in $ntpservers; do
 if grep "^server $ntpserver " /etc/ntp.conf >> /dev/null; then
 	((ntpservercount += 1))
 fi
done

if grep "^server rhel" /etc/ntp.conf; then
 varntp=1
else
 varntp=0
fi

#Set TimeZone/Time
 	
 	case $OS in
 	
 	 RHEL6) echo "Configuring..."
 	 				echo ""
					if [ $vartimezone -eq 1 ]; then
					 echo "TimeZone Updating"
					 echo ""
					 sed -i 's/^ZONE=.*$/ZONE="UTC"/' /etc/sysconfig/clock
 	 				 /usr/sbin/tzdata-update
 	 				fi
 	 				
					if [ $varntp -eq 1 ] || [ $ntpservercount -lt 5 ]; then
					 echo "Setting servers in /etc/ntp.conf"
					 echo ""
					 sed -i '/^server/d' /etc/ntp.conf
 	 				 echo -e "ntpserver1.localhost" >> /etc/ntp.conf
 	 				 echo -e "ntpserver2.localhost" >> /etc/ntp.conf
	 				fi
	 				echo "Making Sure Time is in sync..."
					service ntpd stop
					ntpdate ntpserver1.localhost
					service ntpd start
					echo "Time Should now be set"
					;;
 				
 	 RHEL7) echo "Configuring..."
 	 				if [ $vartimezone -eq 1 ]; then
 	 				 echo "TimeZone Updating"
					 echo ""
 	 				 timedatectl set-timezone UTC
 	 				fi

					if [ $varntp -eq 1 ] || [ $ntpservercount -lt 5 ]; then
					 echo "Setting servers in /etc/ntp.conf"
					 echo ""					
					 sed -i '/^server/d' /etc/ntp.conf
 	 				 echo -e "server ntpserver1.localhost maxpoll 10" >> /etc/ntp.conf
 	 				 echo -e "server ntpserver2.localhost maxpoll 10" >> /etc/ntp.conf
	 				fi
  				echo "Making Sure Time is in sync..."
					systemctl stop ntpd
					ntpdate ntpserver1.localhost
					systemctl start ntpd
					echo "Time Should now be set"
					;;
					
 	esac
 	
echo ""
echo "TimeZone and Time sync should be updated now"
echo ""
echo "---------------------------------------"
echo ""