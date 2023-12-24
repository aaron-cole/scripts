#!/bin/bash

# open a kerberos ticket using keytab authentication if needed
/usr/bin/kinit host/idmserver.myidm.local@MYIDM.LOCAL -k -t /etc/krb5.keytab 

# how many days before expiry? at which point a single email should be sent out
THENUMBEROFDAYS=14

# queries the ldap server for whatever group you want, or search parameters you want to use
# grepping memberUid for the group you want and piping to awk results in a list of users
USERLIST=$(ldapsearch -x -b cn=web_users,cn=groups,cn=compat,dc=myidm,dc=local | grep memberUid | awk '{print $2}' | grep -v admin)

# gets todays date in the same format as ipa
TODAYSDATE=$(date +"%Y%m%d")

# converts to seconds
CALCTODAY=$(date -d "$TODAYSDATE" +%s)

# start the main loop
for USER in $USERLIST; do

# DEBUG line # echo "Checking Expiry For $USER"

# gets date, removes time uses cut to get only first 8 characters of date
LASTLOGINDATE=$(ipa user-show $USER --all | grep krblastsuccessfulauth | awk '{print $2}' | cut -c 1-8)

# accounting for null returns in EXPIRYDATE
if [ -z $LASTLOGINDATE ]; then
 LASTLOGINDATE="19700101"
fi

# 60 days from last login
EXPIRYDATE=$(date -d "$LASTLOGINDATE + 30 days" +"%Y%m%d")

# using date command to convert to a proper date format for the subtraction of days left
CALCEXPIRY=$(date -d "$EXPIRYDATE" +%s)
SECSLEFT=$(expr $CALCEXPIRY - $CALCTODAY)
DAYSLEFT=$((SECSLEFT/60/60/24))

echo "$USER has $DAYSLEFT left"

#Get email address
EMAIL="$(ipa user-show $USER | grep -i email | sed 's/^.*: //')"

# send out an email if it is less than or equal to the number of days left
if [ $DAYSLEFT -le $THENUMBEROFDAYS ];
then

# create the email content
mailsubject="Inactive User [DO_NOT_REPLY]"
mailbody="Policies requires all users to log on at least every 30 days. Your account, $USER IDM account, has not detected a login since $(date -d $EXPIRYDATE +%D) . 
Since this account is only used to access the web interface, please login and use Certificate Login.  Otherwise in $THENUMBEROFDAYS days, your account will be disabled.   
Once disabled, to reactive your account will require a ticket and an administrator will have to reenable it.

ACTION REQUIRED - Please login in with your account"

# send the email out
#   echo $mailbody | mailx -r admin@myidm.local -s "$mailsubject" $EMAIL

   echo "NEED TO SEND EMAIL"
#   echo "Mail Subject - $mailsubject"
#   echo "Mail Body - $mailbody"

fi
done