#!/usr/bin/sh
##########################################################
# /etc/ssh/ssh-ldap-wrapper.sh
# 
# This script was created to connected to RedHat IDM server
# also known as a freeipa server, for ssh public key logins
# to work.  This script will search the idm server for the
# user name ($1) by open-ssh on Solaris 
# and return the ssh rsa-key for the user, compare current
# keys and add if necessary.  Also added lines to create
# home directory, since no pam_mkhomedir exists in solaris.
# 
# Modification of this file is very bad and could stop ssh logins 
# from happening, unless using in a different environment.
# Otherwise modify the variables as needed.
#
# This is valid for Solaris 11.3 and no other OS.
# Do not use on a different OS.
#
# This file was created:
# By Aaron Cole
#                                                                                                                    
# Date:
# 5/22/2019
#
# Change Log:
# Version 1.0 - 5/22/2019: 
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
umask 0077
my_pid=$$
host_rule_file="/tmp/host_rule_file.$my_pid"
user_rule_file="/tmp/user_rule_file.$my_pid"
userallow=0


check_rule()
{

#We are going to check the rule for "enable/allow" and "service ssh/all"
if /usr/bin/ldaplist -l cn=hbac '&('"$rule"')'"$filter" > /dev/null 2>&1 ; then
 usercheck=1
fi

}


/usr/bin/ldaplist -l cn=computers,cn=accounts "$(hostname)*" 2>>/dev/null | grep hbac | sed 's/^.*memberOf: //g' | cut -f 1 -d "," >> $host_rule_file
/usr/bin/ldaplist -l passwd "$uid" 2>>/dev/null | grep hbac | sed 's/^.*memberOf: //g' | cut -f 1 -d "," >> $user_rule_file

#ALLOW
#Compare Rules First only going to deal with matches in both
for rule in $(cat $host_rule_file $user_rule_file | sort | uniq -d); do

#Process if user hasn't been allowed already 
  if  [ "$userallow" -eq 0 ]; then
		 
		 filter='(objectClass=ipahbacrule)(ipaEnabledFlag=TRUE)(accessRuleType=allow)(|(serviceCategory=all)(memberService=sshd))'
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
    filter='(objectClass=ipahbacrule)(ipaEnabledFlag=TRUE)(accessRuleType=allow)(|(serviceCategory=all)(memberService=sshd))(|(hostCategory=all)(userCategory=all))'
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

		 filter='(objectClass=ipahbacrule)(ipaEnabledFlag=TRUE)(accessRuleType=deny)(|(serviceCategory=all)(memberService=sshd))'
     check_rule

     if [ "$usercheck" -eq 1 ]; then
        # This deny rule matched, just cleanup and dump out with error
          rm -rf $host_rule_file > /dev/null 2>&1
  		  	rm -rf $user_rule_file > /dev/null 2>&1
          exit 2
     fi

done

#Cleanup
rm -rf $host_rule_file > /dev/null 2>&1
rm -rf $user_rule_file > /dev/null 2>&1

# User is allowed to login, pull the pubkey.  Echo to stdout will pass 
# it back to our caller, the sshd process.

if [ "$userallow" -ge 1 ]; then
 keys="$(/usr/bin/ldaplist -l passwd "$uid" | grep ipaSshPubKey | awk '{print $2" "$3}')"
 echo "$keys"

 #If home dir doesn't exist got to create it
 if [ ! -d ~$uid ]; then
  gid="$(getent passwd $uid | cut -f 4 -d ":")"
  mkdir -p ~$uid
  cp /etc/skel/* ~$uid/
  chown -R $uid:$gid ~$uid
  chmod 700 ~$uid
  exit 0

#Otherwise chown/chmod homedir
 else
  gid="$(getent passwd $uid | cut -f 4 -d ":")"
  chown -R $uid:$gid ~$uid
  chmod 700 ~$uid  
  exit 0
 fi
fi