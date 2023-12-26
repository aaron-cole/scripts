#!/bin/bash
#setup
#Get Kerberos Credentials
/usr/bin/kinit host/idmserver.myidm.local@MYIDM.LOCAL -k -t /etc/krb5.keytab

#variables
grpdn="cn="admins",cn=groups,cn=compat,dc=myidm,dc=local"
grpname="$(echo "$grpdn" | cut -f 1 -d "," | cut -f2 -d "=")"
reportfile="/tmp/$grpname_report.csv"
echo "User login,Display name,Email address,Org. Unit,Job Title" > $reportfile
mailsubject="Review of Accounts from IDM"
mailbody="This is an automated email. The attached report is a list of all of the accounts in the $grpname group in IDM. "

#echo "Please enter email recipients seperated by a space"
#read emaillist
emaillist="aaroncole@myidm.local"
users="$(ldapsearch -Y GSSAPI -b $grpdn | grep memberUid | grep -v admin | awk '{print $2}' 2>/dev/null)" 
############################################################

for user in $users; do  
ipa user-show "$user" --all | egrep "User login|Display name|Org. Unit|Email address|Job Title" | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 'N;N;N;N;s/\n/,/g' >> $reportfile
done

echo $mailbody | mailx -r admin@myidm.local -s "$mailsubject" -a $reportfile $emaillist

rm $reportfile
kdestroy
