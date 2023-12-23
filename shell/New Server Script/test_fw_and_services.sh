#!/bin/bash

fnusage()
{
echo "USAGE {SCRIPT NAME} [option] [option] ...

Options
-h	| --help	-displays this message

-d| --dns		-test DNS functionality
-i| --idm		-test IDM ports/Servers
-m|	--mail	-test Mail/Postfix Connection
-n| --nb		-test Netbackup Connection
-s|	--sat		-test Satellite Connection

"
}

fntestdns()
{
#TEST DNS First
echo "Testing DNS Reachability and Functionality"
echo ""
SERVERSTOTEST="server1 server2"
FAILURE=0
for SERVERTOTEST in $SERVERSTOTEST; do
 dig +short @8.8.8.8 A "$SERVERTOTEST" >> /dev/null
 if [[ $? -ne 0 ]]; then
 echo "DNS Failure"
 ((FAILURE+=1))
 fi
done

if [[ "$FAILURE" -eq 0 ]]; then
 echo "DNS Appears to be working"
fi

}

fntestsat()
{
#Test Satellite Connection
echo "Testing Satellite ports to see if they are open"
echo ""

SATSTATUS=0
SATPORTS="80 443 5222"

for SATPORT in $SATPORTS; do
 timeout 2 bash -c 'cat < /dev/null > /dev/tcp/satellite.localhost/'$SATPORT
 if [ $? -ne 0 ]; then
	SATSTATUS+=1
 fi
done

#Tell User the Result
if [ $SATSTATUS -gt 0 ]; then
	echo "FAILURE - Satellite Ports are not open"
	echo ""
else
  echo "Congrats! Satellite Ports are open"
	echo ""
fi

}

fntestidm()
{
#Test IDM Connection

echo "Testing IDM ports to see if they are open"
echo ""

IDMSTATUS=0
IDMPORTS="389 636 88 464"
IDMSVRS="rhelidmserver.myidm.localhost rhelidmserver2.myidm.localhost"

for IDMSVR in $IDMSVRS; do
 for IDMPORT in $IDMPORTS; do
  timeout 2 bash -c 'cat < /dev/null > /dev/tcp/'$IDMSVR'/'$IDMPORT
  if [ $? -ne 0 ]; then
	 IDMSTATUS+=1
  fi
 done
done

#Tell User the Result
if [ $IDMSTATUS -gt 0 ]; then
	echo "FAILURE - IDM Ports are not open or there is a DNS failure"
	echo ""
else
  echo "Congrats! IDM Ports are open"
	echo ""
fi

}

fntestmail()
{
#####################
#Postfix
echo "By default we will check connection to servermail.localhost"

timeout 2 bash -c 'cat < /dev/null > /dev/tcp/servermail.localhost/25'
if [ $? -ne 0 ]; then
 echo " FAILURE - Port 25 to servermail.localhost is not open"
else
 echo "Congrats! Port 25 to servermail.localhost is open"
fi

echo "Checking /etc/postfix/main.cf for different relay"
RELAYHOST="$(grep "^relayhost = " /etc/postfix/main.cf | awk '{print $3}')"
if [[ "$RELAYHOST" = "servermail.localhost" ]] || [[ -z $RELAYHOST ]]; then
 echo "postfix has servermail.localhost or is empty"
 echo "Nothing else to Check"
else
 timeout 2 bash -c 'cat < /dev/null > /dev/tcp/'$RELAYHOST'/25'
 if [ $? -ne 0 ]; then
  echo " FAILURE - Port 25 to $RELAYHOST is not open"
 else
  echo "Congrats! Port 25 to $RELAYHOST is open"
 fi
fi

echo "Lets try a test email"
echo ""
read -p 'PLEASE ENTER YOU EMAIL Address:' varemail
echo ""

echo "Sending test email through $RELAYHOST"
date | /bin/mailx -s "Test from `hostname` at `date -u +%y%m%d` through $RELAYHOST" "$varemail"

echo "Sending test email through servermail.localhost"
date | /bin/mailx -s "Test from `hostname` at `date -u +%y%m%d` through servermail.localhost" -S servermail.localhost "$varemail"

echo ""
echo "If you get them then you are good to go"
echo ""

}

fntestnb()
{
#####################
#NETBACKUP

if [ -f /usr/openv/netbackup/bp.conf ]; then 
 echo "Testing Netbackup ports to see if they are open"
 echo ""
 MASTERSERVER="$(grep "^SERVER = " /usr/openv/netbackup/bp.conf | head -n 1 | awk '{print $3}')"
 NBSTATUS=0
 NBPORTS="1556 13724"
 
 for NBPORT in $NBPORTS; do
  timeout 2 bash -c 'cat < /dev/null > /dev/tcp/'$MASTERSERVER'/'$NBPORT
  if [ $? -ne 0 ]; then
	 NBSTATUS+=1
  fi
 done

#Tell User the Result
 if [ $NBSTATUS -gt 0 ]; then
	echo "FAILURE - Netbackup Ports are not open"
	echo ""
 else
  echo "Congrats! Netbackup Ports are open"
	echo ""
 fi

 /usr/openv/netbackup/bin/bpclntcmd -pn -verbose

else
 echo "Netbackup does not appear to be installed"
fi

}

fntesttw()
{
#####################
#TRIPWIRE
echo "Testing TRIPWIRE ports to see if they are open"
echo ""

TWSTATUS=0
TWPORTS="9898 8080 5670"

for TWPORT in $TWPORTS; do
 timeout 2 bash -c 'cat < /dev/null > /dev/tcp/tripwireserver.localhost/'$TWPORT
 if [ $? -ne 0 ]; then
	TWSTATUS+=1
 fi
done

#Tell User the Result
if [ $TWSTATUS -gt 0 ]; then
	echo "FAILURE - TRIPWIRE Ports are not open"
	echo ""
else
  echo "Congrats! TRIPWIRE Ports are open"
	echo ""
fi

}

#################
for arg in "$@"; do
 case $1 in 
 	-h | --help ) fnusage
 								exit;;
	-d | --dns )	fntestdns
								shift;;
	-i | --idm )	fntestidm
								shift;;
	-m | --mail )	fntestmail
								shift;;
	-n | --nb )		fntestnb
								shift;;
	-s | --sat )	fntestsat
								shift;;
	-t | --tw )		fntesttw
								shift;;
	* ) shift;;
 esac
done

