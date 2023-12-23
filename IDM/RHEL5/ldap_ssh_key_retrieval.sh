#!/bin/bash
##############################################################
# name.sh
# 
# This script was created for RHEL5 for ssh certificate
# authentictation to Redhat idM also known as a freeipa server.
# RHEL5 does not include the authorizedkeyscommand option
# in sshd_config.  So this script is made to connection to idM
# and check all HBAC rules, verify it's active, allow, and for
# this host, and grab all user keys and put into 1 file for
# sshd_config to look in to. So use the authorized_keys
# option in sshd_config, and copy all local users keys to file
# Run this script for initial connection.  
# Setup as a cron job perferably every 15 mins
# 
# Modification of this file can be very bad and may stop ssh  
# logins from happening.  Especially if a new key is published.
# Otherwise modify the variables as needed.
#
# This is valid for RHEL5 and no other OS.
# Do not use on a different OS.
# You must have ldapsearch provided by the openldap-clients rpm.
# This was tested with openldap-clients-2.3.43-29.el5_11 rpm.
#
# Currently this script does not look at the following items:
#	1. Polcies that are deny
#		-Off the wall to explicitly deny something already denied
#	2. Nested Hostgroups and Nested Usergroups
#		-May add later
#	3. Does not look for Services in policies
#		-May add later
#
# This file was created:
# By Aaron Cole
#                                                                                                                    
# Date:
# 8/31/2016
#
# Change Log:                                                                                                        
# 8/31/2016: Initial Creation
# 10/20/2016: updated for multiple keys to be pulled 
#             and processed.
##############################################################
# 1. ssh_store needs to be the location of authorizedkeysfile
#  that's in sshd_config.
# 2. logfile should be a location where log files are stored. 
##############################################################
#Variable Assignment
ldapserver="ldap://rhelidmserver.myidm.local"
binddn="uid=myproxy,ou=profile,dc=myidm,dc=local"
bindpass='P@ssW0rdP@ssW0rd'
basedn="dc=myidm,dc=local"
usrdn="cn=users,cn=accounts,dc=myidm,dc=local"
hbacdn="cn=hbac,dc=myidm,dc=local"
hostgrpdn="cn=hostgroups,cn=accounts,dc=myidm,dc=local"
usrgrpdn="cn=groups,cn=accounts,dc=myidm,dc=local"
logfile="/var/log/add_user_ssh_key.log"
#logfile="/tmp/logfile"
#10/20/2016 added new varaiable
temp_store="/tmp/ssh_keys"
ssh_store="/etc/ssh/keys"
hbac_rules_cn="/tmp/hbac_rules_cn"
temp_hbac_rule="/tmp/hbac_temp"
rule_file="/tmp/rule_file"
##############################################################
#Function to retrieve user cert 
# $1 should be "uid=username" 
UserCertAdd() {
if [ -z $1 ]; then
	return
fi

usrname=$(echo $1 | cut -f 2 -d "=")
ssh_key_file="$ssh_store/$usrname/authorized_keys"

#Check if user is disabled to skip
usrcheck=$(ldapsearch -xLLL -H $ldapserver -b $usrdn -D $binddn -w $bindpass $1 nsaccountlock | sed -n '/^ /{H;d};/nsaccountlock:/x;$g;s/\n *//g;s/nsaccountlock: //gp')
if [[ "$usrcheck" == "TRUE" ]]; then
	rm -rf $ssh_key_file
	echo "$1 authorized_key file removed - Acct is disabled" >> $logfile
	return
fi

#Create dirs and file if not there
if [ ! -d $ssh_store/$usrname ]; then
	mkdir -p $ssh_store/$usrname
	touch $ssh_key_file
fi

if [[ "$1" == "all" ]]; then
	keys="$(ldapsearch -xLLL -H $ldapserver -b $basedn -D $binddn -w $bindpass ipaSshPubKey | sed -n '/^ /{H;d};/ipaSshPubKey:/x;$g;s/\n *//g;s/ipaSshPubKey: //gp')"
else
	#10-20-2016 changed processing of keys to handle multiple entries
	returned_keys="$(ldapsearch -xLLL -H $ldapserver -b $basedn -D $binddn -w $bindpass "(&(objectClass=posixAccount)($1))" ipaSshPubKey | sed -n '/^ /{H;d};/ipaSshPubKey:/x;$g;s/\n *//g;s/ipaSshPubKey: //gp')"
	echo $returned_keys | awk '{for (i = 1; i <= NF; i += 2) printf "%s %s\n", $i, $(i+1)}' > $temp_store
fi

for key in "$(cat $temp_store)"; do
	if grep "$key" $ssh_key_file >> /dev/null; then
		echo "$1 Key already in $ssh_key_file" >> $logfile
	else
#		echo "#$1" >> $ssh_key_file
		echo "$key" >> $ssh_key_file &&	echo "Added to $ssh_key_file" >> $logfile
	fi
done

#10-20-2016 don't need anymore
#sed -ie 'N;s/\n/ /' $ssh_key_file 
}
##############################################################
###Actual Script start###
#Do not edit below this##
##############################################################
echo "$(date) Start" >> $logfile

#Have to make key dir to store keys
if [ ! -d $ssh_store ]; then
 mkdir $ssh_store
fi

#Get all hbac rules and dump to file 
ldapsearch -xLLL -H $ldapserver -b $hbacdn -D $binddn -w $bindpass "(objectClass=ipahbacrule)" cn  > $temp_hbac_rule

#Clean results and place into working file
#remove temp file - done with it
grep ^cn $temp_hbac_rule > $hbac_rules_cn
rm -rf $temp_hbac_rule

#Start to Loop through each rule
for rule in $(cat $hbac_rules_cn); do
 echo "Start $rule processing" >> $logfile
 host=0
#Cleanup those pesky cn: entries
 if [[ $rule != "cn:" ]]; then

#Search Ldap for the complete rule and dump into file
 ldapsearch -x -H $ldapserver -b $hbacdn -D $binddn -w $bindpass cn=$rule > $rule_file
 
#Only care if it is an enabled policies
if grep "^ipaEnabledFlag: TRUE" $rule_file >> $logfile; then

#Only looking at allows 
#does not support denies at this time
if grep "^accessRuleType: allow" $rule_file >> $logfile; then

#Check to see if Rule applies to this host
#We only care if we see current host
#Does not support nested host or user groups 
#Grab host rule entires from rule
#We only care if the rule is all
#Or if defined by host
#Or if defined by hostgroup
	case "$(egrep "^hostCategory|^memberHost" $rule_file)" in
		hostCategory*)	host=1 ;;
		memberHost*)		for hostentry in $(grep "^memberHost" $rule_file); do
							case "$hostentry" in
								*fqdn=$(hostname)*)	host=1 ;;
								*cn=hostgroups*)	hostgrpcn="$(grep $hostentry $rule_file | cut -f 2 -d " " | cut -f 1 -d "," )"
													echo "testentry" >> /dev/null
													if ldapsearch -x -H $ldapserver -b $hostgrpdn -D $binddn -w $bindpass $hostgrpcn | grep $(hostname) >> /dev/null ; then
													host=1
													fi ;;
								*)					echo "$rule_cn $hostentry" >> $logfile	;;
							esac
							done ;;	
		*)				echo "Did Not recognize host rules in $rule" >> $logfile ;;
	esac

#We will only process user info
#if rules apply to this host
if [[ $host == 1 ]]; then

#Grab user rule entries
#If all - grab all keys
#if a single uid - grab the key
#check groups and grab all related keys 
	case "$(egrep "^userCategory|^memberUser" $rule_file)" in 
		userCategory*)	UserCertAdd all ;;
		memberUser*)		for userentry in $(grep "^memberUser" $rule_file); do
							case "$userentry" in
								*uid*)				usrid="$(grep $userentry $rule_file | cut -f 2 -d " " | cut -f 1 -d",")"
													UserCertAdd $usrid ;;													
								*cn=groups*)		usergroupcn="$(grep "$userentry" $rule_file | cut -f 2 -d " " | cut -f 1 -d "," )"
													for f in $(ldapsearch -x -H $ldapserver -b $usrgrpdn -D $binddn -w $bindpass $usergroupcn | grep "^member:" | cut -f 2 -d " " | cut -f 1 -d ","); do
													UserCertAdd $f
													done ;;
								*)					echo "$rule_cn $userentry" >> $logfile ;;
							esac
						done ;;	
		*)				echo "Did not recognize user rules in $rule" >> /$logfile ;;
	esac
fi
fi		#End of pesky cn entry cleanup
fi		#End of accessRuleType
fi 		#End of ipaEnabledFlag
done 	#End of for each rule

#Set Perms on key files
#Otherwise ssh won't like the key
for dir in $(ls $ssh_store); do
	chmod 600 $ssh_store/$dir/authorized_keys
	chmod 700 $ssh_store/$dir
	chown -R $dir $ssh_store/$dir
done

#Cleanup
rm -rf $hbac_rules_cn $rule_file $temp_store
