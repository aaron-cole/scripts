#!/bin/bash

#Check if running as root
if [ "$(id -u)" != "0" ]; then
	echo "This has to be run as root" 1>&2
	exit 1
fi

#INTERFACE WITH IP/MGMT/AZURE????

#Get Interface
PASS=0
while [ $PASS -eq 0 ]; do
 case $(ip addr | grep "^[0-9]:" |grep -v lo | cut -f 2 -d ":" | wc -l) in
 	0) 	echo "No interface found. exiting..."
		exit 2;;
 	1) 	varipinterface="$(ip addr | grep "^[0-9]:" |grep -v lo | cut -f 2 -d ":" | awk '{print $1}')"
 		echo "Only 1 interface found - we will use this one - $varipinterface"
 		PASS=1;;
 	*) 	IFPASS=0
 		while [ $IFPASS -eq 0 ]; do
 		 echo "Multiple interfaces found"
 		 ip addr | grep "^[0-9]:" |grep -v lo| cut -f2 -d:
 		 echo ""
 		 read -p 'Interface Name: ' varipinterface
 		 if ip addr | grep "^[0-9]:" |grep -v lo | cut -f 2 -d ":" | awk '{print $1}' | grep "$varipinterface" >>/dev/null; then
		  IFPASS=1
		  PASS=1
		 else
		  echo "Try Again, can't validate what you typed"
         fi
		done;;
 esac
done

varipaddr="$(ip addr show dev $varipinterface | grep "inet " | awk '{print $2}' | awk -F/ '{print $1}')"

#Verify DNS
DNSSTAT=0
echo ""
echo "---------Verifying DNS---------"
#Forward
if dig +noall +answer $(hostname) | grep "$varipaddr" ; then
 echo "Forward DNS is working"
else
 echo "Forward DNS is not working - contact DNS or check hostname"
 ((DNSSTAT+=1))
fi
echo ""
#Reverse
if dig +noall +answer -x $varipaddr | grep $(hostname) ; then
 echo "Reverse DNS is working"
else
 echo "Reverse DNS is not working - contact DNS or check hostname"
 ((DNSSTAT+=1))
fi
echo ""
echo "---------------------------------------"
echo ""
if [ $DNSSTAT -gt 0 ]; then
	echo "DNS Verification Unsuccessful - See above"
else
	echo "DNS Verification Successfull"
fi
	