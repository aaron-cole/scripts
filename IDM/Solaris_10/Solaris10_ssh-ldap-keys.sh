#!/usr/bin/bash
##########################################################
# /etc/ssh/ldap_ssh_key_retrieval.sh
# 
# This script was created for Solaris 10 ssh certificate
# authentictation to Redhat idM also known as a freeipa server.
# Sol 10 does not include the authorizedkeyscommand option
# in sshd_config.  So this script is made to connection to idM
# and check all HBAC rules, verify it's active, allow, and for
# this host, and grab all user keys and put into 1 file for
# sshd_config to look in to. So use the authorized_keys
# option in sshd_config, and copy all local users keys to file
# Run this script for initial connection.  
# Setup as a cron job perferably every 15 mins
# 
# Modification of this file can be very bad and may stop new ssh  
# logins from happening.  Especially if a new key is published.
# Otherwise modify the variables as needed.
#
# This is valid for Solaris 10 and no other OS.
# Do not use on a different OS.
# You must have /usr/bin/ldapsearch provided by the openldap-clients rpm.
# This was tested with openldap-clients-2.3.43-29.el5_11 rpm.
#
# Currently this script does not look at the following items:
# 1. Polcies that are deny
#   -Off the wall to explicitly deny something already denied
# 2. Nested Hostgroups and Nested Usergroups
#   -May add later
#
# This file was created:
# By Aaron Cole
#                                                                                                                    
# Date:
# 12/27/2016
#
# Change Log:
# Version 1.0                                                                                                        
# 12/27/2016: Initial Creation
#
##########################################################
#Variable Assignment
binddn="uid=myproxy,ou=profile,dc=myidm,dc=local"
bindpass='P@ssW0rdP@ssW0rd'
basedn="dc=myidm,dc=local"
usrdn="cn=users,cn=accounts,dc=myidm,dc=local"
hbacdn="cn=hbac,dc=myidm,dc=local"
hostgrpdn="cn=hostgroups,cn=accounts,dc=myidm,dc=local"
usrgrpdn="cn=groups,cn=accounts,dc=myidm,dc=local"
logfile="/var/adm/ldap-key.log"
temp_store="/tmp/ssh_keys"
hbac_rules_cn="/tmp/hbac_rules_cn"
temp_hbac_rule="/tmp/hbac_temp"
rule_file="/tmp/rule_file"
ldapservers="$(/usr/sbin/nslookup -type=SRV _ldap._tcp.myidm.local | grep "^_ldap" | awk '{ print $7}' | sed s/.$//)"
ldapserver="$(echo $ldapservers | cut -f 1 -d " ")"
##########################################################
#Function to Check Rule
CheckRule() {
#$1 should be rule
if [ -z $1 ]; then
 return
fi

 echo "Start $1 processing" >> $logfile
 HOST=0
 ENABLED=0
 ALLOW=0
 SERVICE=0
 
#Search Ldap for the complete rule and dump into file
 /usr/bin/ldapsearch -x -h $ldapserver -b $hbacdn -D $binddn -w $bindpass cn=$1 > $rule_file

#See if Enabled
if grep "^ipaEnabledFlag: TRUE" $rule_file >> /dev/null; then
 echo "Enabled" >> $logfile
 ENABLED=1
else
 echo "disabled" >> $logfile
 return
fi

#See if Allow
if grep "^accessRuleType: allow" $rule_file >> /dev/null; then
 echo "Allow Rule" >> $logfile
 ALLOW=1
else
 echo "Deny Rule" >> $logfile
fi

#See if ssh is included
if grep "^serviceCategory: all" $rule_file >> /dev/null; then
 echo "All Services" >> $logfile
 SERVICE=1
elif grep "^memberService: cn=sshd" $rule_file >> /dev/null; then
 echo "ssh defined" >> $logfile
 SERVICE=1
else 
 echo "no ssh" >> $logfile
 return
fi

#See if applies to host
if grep "^hostCategory: all" $rule_file >> /dev/null; then
 echo "All Hosts" >> $logfile
 HOST=1
elif grep "^memberHost" $rule_file >> /dev/null; then
 for hostentry in $(grep "^memberHost" $rule_file); do
  case $hostentry in
   *fqdn=$(hostname)*) HOST=1 ;;
   *cn=hostgroups*) hostgrpcn="$(echo $hostentry | cut -f 1 -d "," | cut -f 2 -d "=" )"
                    if ldaplist -l netgroup $hostgrpcn | grep $(hostname) >> $logfile; then
                     HOST=1
                    fi ;;
   *) echo "$hostentry not found" >> $logfile ;;
  esac
 done
 if [[ $HOST == 0 ]]; then
  return
 fi
else
 return
fi

#check user/group
if grep "^userCategory: all" $rule_file >> /dev/null; then
 echo "All Users" >> $logfile
 for allusrID in $(ldaplist -l cn=users,cn=accounts | grep "^dn:"| cut -f 2 -d " " | cut -f 1 -d "," | cut -f 2 -d "="); do
  UserCertAdd $allusrID
 done
fi

if grep "^memberUser" $rule_file >> /dev/null; then
 for userentry in $(grep "^memberUser" $rule_file); do
  case $userentry in
   *uid=*)  usrID="$(echo $userentry | cut -f 1 -d "," | cut -f 2 -d "=")"
   					UserCertAdd $usrID;;
   *cn=groups*) usergrp="$(echo $userentry | cut -f 1 -d "," | cut -f 2 -d "=" )"
                for userID in $(ldaplist -l group $usergrp | grep "memberUid:" | cut -f 2 -d ":"); do
                 UserCertAdd $userID
                done ;;
   *) echo "$userentry not found" >> $logfile ;;
  esac
 done
fi

}
#######################
#Function to Add Certs
UserCertAdd() {
#$1 should be username
if [ -z $1 ]; then
 return
fi

homedir="$(getent passwd $1 | cut -f 6 -d ":")"
ssh_dir="$homedir/.ssh"
ssh_key_file="$ssh_dir/authorized_keys"

#Check if user is disabled to skip
if /usr/bin/ldapsearch -xLLL -h $ldapserver -b $usrdn -D $binddn -w $bindpass uid=$1 nsaccountlock | grep nsaccountlock | grep -i "true" >> /dev/null; then
 if [ -f $ssh_key_file ]; then
  rm $ssh_key_file
  echo "$1 authorized_key file removed - Acct is disabled" >> $logfile
 fi
 echo "$1 is disabled not processing" >> $logfile
 return
fi

#Create dirs and file if not there
if [ ! -d $homedir ]; then
 umask 077
 mkdir -p $ssh_dir
 cp /etc/skel/* $homedir
 touch $ssh_key_file
 chown -R $1:$(getent passwd $1 | cut -f 4 -d ":") $homedir
fi

if [ ! -d $ssh_dir ]; then
 umask 077
 mkdir $ssh_dir
 touch $ssh_key_file
 chown -R $1:$(getent passwd $1 | cut -f 4 -d ":") $homedir
fi

if [ ! -f $ssh_key_file ]; then
 umask 077
 touch $ssh_key_file
 chown -R $1:$(getent passwd $1 | cut -f 4 -d ":") $homedir
fi

ldaplist -l passwd $1 | grep "ipaSsh" | awk '{print $2,$3}' > $temp_store

while read key; do
 if grep "$key" $ssh_key_file >> /dev/null; then
  echo "$1 Key already in $ssh_key_file" >> $logfile
 else
  echo "$key" >> $ssh_key_file && echo "Added to $ssh_key_file" >> $logfile
 fi
done <$temp_store

return
}
####################################
#Start of script
####################################
echo "####################################" >> $logfile
echo "$(date) Start" >> $logfile

#Get all hbac rules from server and dump to file 
/usr/bin/ldapsearch -xLLL -h $ldapserver -b $hbacdn -D $binddn -w $bindpass "(objectClass=ipahbacrule)" cn > $temp_hbac_rule

#Clean results and place into working file
#remove temp file - done with it
grep "^cn" $temp_hbac_rule | cut -f 2 -d " " > $hbac_rules_cn
rm -rf $temp_hbac_rule

#Start to Loop through each rule
for rule in $(cat $hbac_rules_cn); do
 CheckRule $rule
done

#Cleanup
rm -rf $hbac_rules_cn $rule_file $temp_store