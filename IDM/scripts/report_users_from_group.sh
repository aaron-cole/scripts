#!/bin/bash
####Variables####
# Keytab Principal to invoke
krb_princ="host/idmserver.myidm.local@MYIDM.LOCAL"

# Full dc of environment
DC_item="dc=myidm,dc=local"

# GRPDN
# don't forget end comma
grpcns="cn=mygroup,cn=groups,cn=compat,"

reportfile="/tmp/report.csv"
mailsubject="Review of Accounts from MYIDM.LOCAL"
mailbody="This is an automated email. The attached report is a review of accounts from MyGroup"

# People who need the report
emaillist="admin@myidm.local"

# IDM Admins added to Email
# Don't forget leading space
emaillist+=" admin2@myidm.local"

####End of Variables####
####Do Not edit below this####
############################################################
#Get Kerberos Credentials
/usr/bin/kinit -k -t /etc/krb5.keytab "$krb_princ"

# Start CSV with headers
echo "User login,Display name,Email address,Org. Unit,Job Title, Account Disable
d, Account Creation Date" > $reportfile

# Get Users from Group
users="$(ldapsearch -Y GSSAPI -b $grpcns$DC_item | grep memberUid | awk '{print 
$2}' 2>/dev/null)"

# For each User
for user in $users; do
# Get their info from IDM, remove unnecessary info
# Format responsibly for csv readability and put into csv
 outputinfo="$(ipa user-show "$user" --all | egrep "User login|Display name|Org. Unit|Email address|Job Title|Account disabled" | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 'N;N;N;N;N;s/\n/,/g')"
 ldap_date="$(ldapsearch -LLL -Y GSSAPI uid=$user createtimestamp 2>/dev/null | grep createtimestamp | cut -f 2 -d" " | cut -c-14)"
 ldap_user_date="$(date -d "${ldap_date:0:8} ${ldap_date:8:2}:${ldap_date:10:2}:${ldap_date:12:2}")"
 outputinfo+=",$ldap_user_date"
# outputinfo+=",$(ldapsearch -LLL -Y GSSAPI uid=$user createtimestamp 2>/dev/null | grep createtimestamp | cut -f 2 -d" ")"
 echo "$outputinfo" >> $reportfile
done

#Send Email
echo $mailbody | mailx -r admin@myidm.local -s "$mailsubject" -a $reportfile $emaillist

#Cleanup
rm $reportfile
kdestroy -A