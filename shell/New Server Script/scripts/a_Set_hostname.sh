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

#Get & Check Hostname for FQDN
PASS=0
echo "---------------------------------------"
echo "Hostname Configuration"
echo ""
while [ $PASS -eq 0 ]; do
 read -p 'Please Enter the New Hostname FQDN:' varhost

#We have to make sure it's all lower case
varhost="$(echo "$varhost" | awk '{print tolower($0)}')"

 if [[ "$varhost" =~ myidm.localhost ]]; then
 	echo ""
 	echo "Hostname provided appears to be a FQDN"
 	PASS=1
 else
  echo ""
  echo "Hostname provided does not appear to be a .myidm.localhost FQDN. Try Again..."
 fi
done

#Verfiy we want to make the change
echo ""
echo "Current Hostname: $(hostname)"
echo "New Hostname: $varhost"
echo ""

#We want a solid answer so we will force
#the user for one
PASS=0
while [ $PASS -eq 0 ]; do
 read -p 'Apply the above change? [y/n]: ' varchoice
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
echo "Setting hostname..."
 
 #Set Hostname
 SETTINGRESULT=0
 case $OS in
 	 RHEL6) 	#Dynamically 
			hostname "$varhost"
			if [ $? -ne 0 ]; then
 			 echo "There was an error in setting the hostname dynamically"
 	 		 ((SETTINGRESULT+=1))
 	 		fi
 	 				
 	 		#Persistantly
 	 		cp /etc/sysconfig/network /etc/sysconfig/network.backup
 	 		sed -i 's/^HOSTNAME=.*$/HOSTNAME='"$varhost"'/' /etc/sysconfig/network
 	 		if [ $? -ne 0 ]; then
 	 		 echo "There was an error in setting the hostname persistantly"
 	 		 ((SETTINGRESULT+=2))
 	 		fi
 	 		;;
 	 				
 	 RHEL7) hostnamectl set-hostname "$varhost"
 	 		if [ $? -ne 0 ]; then
 	 		 echo "There was an error in setting the hostname"
 	 		 ((SETTINGRESULT+=4))
 	 		fi
 	 		;;
 esac

#Verify
 case $SETTINGRESULT in
	1|2|3|4) echo "$(hostname) appears to not have been set.  Do not proceed further"
			 echo ""
			 echo "---------------------------------------"
			 exit
			 ;;
	0)	echo "Hostname set to $(hostname)"
	    echo ""
		echo "---------------------------------------"
		echo ""
		;;
 esac
;; #End of Yes Choice

 *) echo "Canceled. No Changes have been made.";;
esac


