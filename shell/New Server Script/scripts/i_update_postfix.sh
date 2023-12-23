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

read -p 'PLEASE ENTER YOU EMAIL Address:' varemail

#Configure Postfix
STATUS=0
echo ""
echo "Configuring Postfix"
sed -i 's/^mydomain =.*$/mydomain = '"$vardomain"'/' /etc/postfix/main.cf
case $varlocation in
	rh|ho|lo|az) timeout 2 bash -c 'cat < /dev/null > /dev/tcp/mailserver.localhost/25'
					  if [ $? -ne 0 ]; then
						 STATUS+=1
						fi
	          sed -i 's/^relayhost =.*$/relayhost = mailserver.localhost/' /etc/postfix/main.cf;;
	*)  timeout 2 bash -c 'cat < /dev/null > /dev/tcp/mailserver.localhost/25'
			if [ $? -ne 0 ]; then
			 STATUS+=1
			fi
	   sed -i 's/^relayhost =.*$/relayhost = mailserver.localhost/' /etc/postfix/main.cf;;
esac
echo "Done"

#Verify 
if [ $STATUS -gt 0 ]; then
	echo "Port is not open to mail server - need to check if it is open"
fi

#Postfix
echo "Sending test email"
date | /bin/mailx -s "Test from `hostname` at `date -u +%y%m%d`" "$varemail"

echo ""
echo "If you don't receive the email then the following are possibilities to check.."
echo ""
case $varlocation in
	rh|ho|lo|az) echo "The relay host is mailserver.localhost and may need routes to the server";;
	*) echo "The relay host is mailserver.localhost and may need routes to the server";;
esac
echo ""
echo "You may not have port 25 open through the Firewalls"
echo "The relay host may be blocking your traffic"
echo ""
echo "---------------------------------------"
