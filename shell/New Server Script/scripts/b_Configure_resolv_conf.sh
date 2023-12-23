#!/bin/bash

#Check if running as root
if [ "$(id -u)" != "0" ]; then
	echo "This has to be run as root" 1>&2
	exit 1
fi

#Get Domainname
echo "---------------------------------------"
echo "/etc/resolv.conf Configuration"
echo ""
vardomain="$(hostname | cut -f 2- -d ".")"

#Check to make sure it's not blank
case $vardomain in
	*.dla.mil)	echo "This is the Found Domain Name - $vardomain"
				echo "We should use this"
				read -p "Proceed with recommendation? [yes/no]: "
			    echo
			    case $REPLY in
					[Yy][Ee][Ss]) echo "Continuing on with discovered setting";;
					*) echo "Exiting based on your response"
				       exit 1;;
			    esac;;
			
	*)	echo "By the hostname setting it does not appear that it is set correctly"
		echo "Exiting..."
		echo "---------------------------------------"
		exit 1;;
esac

if [[ -z "$vardomain" ]]; then
	echo "We are unable to determine the correct domain name."
	echo "You must configure the Hostname First"
  exit 2
fi


#Configure /etc/resolv.conf
cp /etc/resolv.conf /etc/resolv.conf.backup
echo ""
echo "Configuring /etc/resolv.conf"
chattr -i /etc/resolv.conf
sed -i '/search/d' /etc/resolv.conf
sed -i '/domain/d' /etc/resolv.conf
sed -i '/nameserver/d' /etc/resolv.conf
echo -e "domain $vardomain" >> /etc/resolv.conf
echo -e "nameserver 8.8.8.8" >> /etc/resolv.conf
echo -e "nameserver 1.1.1.1" >> /etc/resolv.conf
chattr +i /etc/resolv.conf
echo ""
echo "The updated /etc/resolv.conf is below"
echo ""
cat /etc/resolv.conf
echo ""
echo "Done Configuring /etc/resolv.conf"
echo ""
echo "backup file is /etc/resolv.conf.backup"
echo "---------------------------------------"


