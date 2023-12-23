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

#Lets check to make sure we can talk to Satellite
#before we try to do anything
STATUS=0

timeout 2 bash -c 'cat < /dev/null > /dev/tcp/satellite.localhost/80'
if [ $? -ne 0 ]; then
	STATUS+=1
fi

timeout 2 bash -c 'cat < /dev/null > /dev/tcp/satellite.localhost/443'
if [ $? -ne 0 ]; then
	STATUS+=1
fi

timeout 2 bash -c 'cat < /dev/null > /dev/tcp/satellite.localhost/5222'
if [ $? -ne 0 ]; then
	STATUS+=1
fi

#Must exit if ports are not open
if [ $STATUS -gt 0 ]; then
	echo "Ports are not open - Unable to add"
	exit 1
fi

#Gotta check for RHN commands that we are using
#If they aren't there can't do anything
if [ ! -f /usr/sbin/rhnreg_ks ]; then
 echo "RHN client tools packages are not installed - Unable to add"
 exit 1
fi

if [ ! -f /usr/bin/rhn-actions-control ]; then
 echo "RHN client tools packages are not installed - Unable to add"
 exit 1
fi

#Going to validate hostname before we continue
case $hostname in
	clone*|azure*) echo "Hostname is not set - exiting"
																			exit 2;;
	*myidm.localhost) echo "Hostname Appears to be set properly"
								echo "Continuing..."
								echo "";;
	
	*) echo "Hostname is not set properly"
		exit 2;;
esac

########################
#Check if already registered, we don't want to add again
if grep $(hostname) /etc/sysconfig/rhn/systemid >> /dev/null; then
	echo ""
	echo "System appears to already be registered"
	echo ""
	echo "There is nothing else to do"
  echo "Exiting..."
  echo ""
  echo "---------------------------------------"
  echo ""
  exit 2
fi

#Start configuration

#Remove old rhn File
rm -rf /etc/sysconfig/rhn/systemid

#up2date file
#Don't care if it exists - lets just create it

 cat <<EOF > /etc/sysconfig/rhn/up2date
# Automatically generated Red Hat Update Agent config file, do not edit.
# Format: 1.0
tmpDir[comment]=Use this Directory to place the temporary transport files
tmpDir=/tmp

disallowConfChanges[comment]=Config options that can not be overwritten by a config update action
disallowConfChanges=noReboot;sslCACert;useNoSSLForPackages;noSSLServerURL;serverURL;disallowConfChanges

skipNetwork[comment]=Skips network information in hardware profile sync during registration.
skipNetwork=0

stagingContent[comment]=Retrieve content of future actions in advance
stagingContent=1

networkRetries[comment]=Number of attempts to make at network connections before giving up
networkRetries=1

hostedWhitelist[comment]=RHN Hosted URLs
hostedWhitelist=

enableProxy[comment]=Use a HTTP Proxy
enableProxy=0

writeChangesToLog[comment]=Log to /var/log/up2date which packages has been added and removed
writeChangesToLog=0

serverURL[comment]=Remote server URL (use FQDN)
serverURL=https://satellite/XMLRPC

proxyPassword[comment]=The password to use for an authenticated proxy
proxyPassword=

stagingContentWindow[comment]=How much forward we should look for future actions. In hours.
stagingContentWindow=24

proxyUser[comment]=The username for an authenticated proxy
proxyUser=

versionOverride[comment]=Override the automatically determined system version
versionOverride=

sslCACert[comment]=The CA cert used to verify the ssl server
sslCACert=/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT

retrieveOnly[comment]=Retrieve packages only
retrieveOnly=0

debug[comment]=Whether or not debugging is enabled
debug=0

httpProxy[comment]=HTTP proxy in host:port format, e.g. squid.redhat.com:3128
httpProxy=

useNoSSLForPackages[comment]=Use the noSSLServerURL for package, package list, and header fetching (disable Akamai)
useNoSSLForPackages=0

systemIdPath[comment]=Location of system id
systemIdPath=/etc/sysconfig/rhn/systemid

enableProxyAuth[comment]=To use an authenticated proxy or not
enableProxyAuth=0

noReboot[comment]=Disable the reboot actions
noReboot=0
EOF

chmod 600 /etc/sysconfig/rhn/up2date

#We are just going to apply the new Cert file
#for Convience.
echo "Updating New Cert File Standby..."

#copy trusted cert of satellite.
#cat <<EOFF > /usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT

#EOFF

echo ""
echo "Standby, adding to Satellite"			
#if [ ! -f /usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT ]; then
#	wget -O - http://satellite/pub/RHN-ORG-TRUSTED-SSL-CERT > /usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT
	chmod 644 /usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT
#fi

case $OS in
 	 RHEL6) /usr/sbin/rhnreg_ks --activationkey=1-mykey --serverUrl https://satellite/XMLRPC
 	 				;;
 	 				
 	 RHEL7) /usr/sbin/rhnreg_ks --activationkey=1-mykey2 --serverUrl https://satellite/XMLRPC
 	        ;;
esac

rhn-actions-control --enable-all

echo "Running yum clean all now"
yum clean all

echo "All done... system is now on Satellite"
echo ""
echo "---------------------------------------"
echo ""