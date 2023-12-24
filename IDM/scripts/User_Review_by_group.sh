#!/bin/bash
############################################################
#
#  Synopsis: Script to Create a csv file based on
#            user group membership.  
#			#1 You must get Kerberos Credentials
#              first by using the kinit command.
#             
#			#2 Group name has to be and arg to the script.
#			   Only 1 group name per report also.
#
#			#3 Email receipients by be a list seperated
#			   by a space
#
############################################################
#setup
#Check if there is a $1
if [ -z $1 ]; then
 echo "you must have a groupname after the script"
 exit 1
fi

#check Kerberos credentials
klist -s
if [ "$?" == "1" ]; then
 echo "You must have Kerberos Credenitals"
 kinit
fi

#variables
reportfile="/tmp/report.csv"
mailsubject="[DO NOT REPLY]Review of Accounts from IDM"
mailbody="This is a review of accounts. If an account is not needed please let the admins know. Otherwise no action is required."
grpdn="cn="$1",cn=groups,cn=compat,dc=myidm,dc=local"
echo "User login,Display name,Email address,Org. Unit,Job Title" > $reportfile

#echo "Please enter email recipients seperated by a space"
#read emaillist
emaillist="aaroncole@myidm.local"
users="$(ldapsearch -Y GSSAPI -b $grpdn | grep memberUid | awk '{print $2}' 2>/dev/null)" 
############################################################

for user in $users; do  
ipa user-show "$user" --all | egrep "User login|Display name|Org. Unit|Email address|Job Title" | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 'N;N;N;N;s/\n/,/g' >> $reportfile
done

echo $mailbody | mailx -s "$mailsubject" -a $reportfile $emaillist

rm $reportfile