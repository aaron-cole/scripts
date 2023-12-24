#!/bin/bash

# open a kerberos ticket using keytab authentication if needed
klist -s
if [[ $? -gt 0 ]]; then
/usr/bin/kinit admin@myidm.local -k -t /home/admin/.krb5/admin.keytab
fi

# how many days before expiry? at which point a single email should be sent out

cd /tmp
THENUMBEROFDAYS=15

#queries the ldap server for whatever group you want, or search parameters you want to use
# grepping memberUid for the group you want and piping to awk results in a list of users
USERLIST=$(ldapsearch -x -b cn=admins,cn=groups,cn=compat,dc=myidm,dc=local | grep memberUid | awk '{print $2}' | grep -v admin)

# start the main loop
for USER in $USERLIST;
do
# gets todays date in the same format as ipa
TODAYSDATE=$(date +"%Y%m%d")
echo "Checking Expiry For $USER"

# gets date, removes time uses cut to get only first 8 characters of date
EXPIRYDATE=$(ipa user-show $USER --all | grep krbpasswordexpiration | awk '{print $2}' | cut -c 1-8)

# using date command to convert to a proper date format for the subtraction of days left
CALCEXPIRY=$(date -d "$EXPIRYDATE" +%j)
CALCTODAY=$(date -d "$TODAYSDATE" +%j)
DAYSLEFT=$(expr $CALCEXPIRY - $CALCTODAY)

#echo "$USER has $DAYSLEFT left"

#Get email address
EMAIL="$(ipa user-show $USER | grep -i email | sed 's/^.*: //')"

# send out an email if it is less than or equal to the number of days left
if [ $DAYSLEFT -le $THENUMBEROFDAYS ];
then

# create the email content
echo "You are receiving this email because the password for your $USER account expires soon. 
Policies require that all user accounts change their password every 60 days." >> $USER.temp
echo " " >> $USER.temp
echo "IDM automation script" >> $USER.temp

# send the email out
 mailx -s "$USER Password is about to expire [DO_NOT_REPLY]" $EMAIL < $USER.temp

# delete content file
rm -rf $USER.temp
fi

done