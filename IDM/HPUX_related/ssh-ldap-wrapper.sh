#!/usr/bin/sh
##########################################################
# /usr/local/bin/ssh-ldap-wrapper
# 
# This script was created to connected to RedHat IDM server
# also known as a freeipa server, for ssh public key logins
# to work.  This script will search the idm server for the
# user name ($1) by ssh on HPUX 
# and return the ssh rsa-key for the user, compare current
# keys and add if necessary.  
# 
# Modification of this file is very bad and could stop ssh logins 
# from happening, unless using in a different environment.
# Otherwise modify the variables as needed.
#
# This is valid for HPUX and no other OS.
# Do not use on a different OS.
#
# This file was created:
# By Aaron Cole
#                                                                                                                    
# Date:
# 4/12/2019
#
# Change Log:
# Version 1.0 - 4/12/2019: 
# -Initial Creation
##########################################################
#Exit if there is not an argument
#argument = username
if [ -z $1 ]; then
 exit 2
fi

#skip if it's a local user
if grep ^$1: /etc/passwd >>/dev/null; then
 exit 0
fi

#Variables
uid="$1"
userdn="uid=myproxy,ou=profile,dc=myidm,dc=local"
userpass="P@ssW0rdP@ssW0rd"
umask 0077
my_pid=$$
compdn="cn=computers,cn=accounts,dc=myidm,dc=local"
usrdn="cn=users,cn=accounts,dc=myidm,dc=local"
hbacdn="cn=hbac,dc=myidm,dc=local"
host_rule_file="/tmp/host_rule_file.$my_pid"
user_rule_file="/tmp/user_rule_file.$my_pid"
userallow=0
servers="$(grep preferredServerList /etc/opt/ldapux/ldapux_profile.ldif | sed 's/^.*: //g' | sed 's/:389//g')"
server_num=0

check_rule()
{

#We are going to check the rules with this for various filters
if [ "$(/opt/ldapux/bin/ldapsearch -x -b $hbacdn -h $server -D $userdn -w $userpass "$filter($rule))")" ] > /dev/null 2>&1  ; then
 usercheck=1
fi

}

####Start of Script

#We are using the First ldapsearch Command to check to see if the 
#Server is usable.  If not go back and get the next one from the 
#ldap profile and try until we have no more servers.
while : ; do
 ((server_num+=1))
 server="$(echo "$servers" | cut -f $server_num -d " ")"
 if [ -z "$server" ]; then
  exit 5
 fi
 /opt/ldapux/bin/ldapsearch -x -b $compdn -h $server -D $userdn -w $userpass fqdn=$(hostname)* 2>>/dev/null | grep hbac | sed 's/^.*memberOf: //g' | cut -f 1 -d "," >> $host_rule_file
 if [ $? -eq 0 ]; then
 	break
 fi
done
	
	
/opt/ldapux/bin/ldapsearch -x -b $usrdn -h $server -D $userdn -w $userpass uid=$uid 2>>/dev/null | grep hbac | sed 's/^.*memberOf: //g' | cut -f 1 -d "," >> $user_rule_file

#ALLOW
#Compare Rules First only going to deal with matches in both
for rule in $(cat $host_rule_file $user_rule_file | sort | uniq -d); do

#Process if user hasn't been allowed already 
  if  [ "$userallow" -eq 0 ]; then
		 
		 filter="(&(objectClass=ipahbacrule)(ipaEnabledFlag=TRUE)(accessRuleType=allow)(|(serviceCategory=all)(memberService=sshd))"
     check_rule

     if [ "$usercheck" -eq 1 ]; then
        userallow=1
     fi

  fi # End of processing if user is already allowed and rule is allow
done

#If we didn't find a match above, user is still denied
#so we have to check Host Rules for "ALL users"
#and we have to check User Rules for "ALL hosts"
if [ "$userallow" -eq 0 ]; then

	for rule in $(cat $host_rule_file $user_rule_file); do

	 if  [ "$userallow" -eq 0 ]; then
    filter="(&(objectClass=ipahbacrule)(ipaEnabledFlag=TRUE)(accessRuleType=allow)(|(serviceCategory=all)(memberService=sshd))(|(hostCategory=all)(userCategory=all))"
		check_rule
   
    if [ "$usercheck" -eq 1 ]; then
        userallow=1
    fi

   fi # End of processing if user is already allowed and rule is allow
  done

fi	

#done with allow rules.  Since the default is deny if we didn't find any
# that matched, then go no further and dump the user out.
if [ "$userallow" -eq 0 ] ; then
  rm -rf $host_rule_file > /dev/null 2>&1
  rm -rf $user_rule_file > /dev/null 2>&1
  exit 2
fi

# Now check to see if we have any deny rules and if at least one matches.
#only get enabled rules to cut down on later searchs

usercheck=0 
#For each Rule
for rule in $(cat $host_rule_file $user_rule_file); do

		 filter="(&(objectClass=ipahbacrule)(ipaEnabledFlag=TRUE)(accessRuleType=deny)(|(serviceCategory=all)(memberService=sshd))"
     check_rule

     if [ "$usercheck" -eq 1 ]; then
        # This deny rule matched, just cleanup and dump out with error
          rm -rf $host_rule_file > /dev/null 2>&1
  		  	rm -rf $user_rule_file > /dev/null 2>&1
          exit 3
     fi

done

# User is allowed to login, pull the pubkey.  Echo to stdout will pass 
# it back to our caller, the sshd process.

if [ "$userallow" -ge 1 ]; then
 keys="$(/opt/ldapux/bin/ldapsearch -b $usrdn -B -x -h $server -D $userdn -w $userpass "(&(uid=$uid)(ipaSshPubKey=*))" 'ipaSshPubKey' | grep ipaSshPubKey | cut -c 14- )"
 echo "$keys"
fi

#Cleanup
rm -rf $host_rule_file > /dev/null 2>&1
rm -rf $user_rule_file > /dev/null 2>&1