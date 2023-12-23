#!/bin/bash

# open a kerberos ticket using keytab authentication if needed
klist -s
if [[ $? -gt 0 ]]; then
/usr/bin/kinit host/idmserver.myidm.local@MYIDM.LOCAL -k -t /etc/krb5.keytab
fi

# how many days before expiry? at which point a single email should be sent out
THENUMBEROFDAYS=14

#Change to /tmp to create users email
cd /tmp

#queries the ldap server for whatever group you want, or search parameters you want to use
# grepping memberUid for the group you want and piping to awk results in a list of users
USERLIST=$(ldapsearch -x -b cn=admins,cn=groups,cn=compat,dc=myidm,dc=local | grep memberUid | awk '{print $2}' | grep -v admin)

# start the main loop
for USER in $USERLIST;
do
# gets todays date in the same format as ipa
TODAYSDATE=$(date +"%Y%m%d")
#echo "Checking Expiry For $USER"

# gets date, removes time uses cut to get only first 8 characters of date
EXPIRYDATE=$(ipa user-show $USER --all | grep krbpasswordexpiration | awk '{print $2}' | cut -c 1-8)

# using date command to convert to a proper date format for the subtraction of days left
CALCEXPIRY=$(date -d "$EXPIRYDATE" +%s)
CALCTODAY=$(date -d "$TODAYSDATE" +%s)
SECSLEFT=$(expr $CALCEXPIRY - $CALCTODAY)
DAYSLEFT=$((SECSLEFT/60/60/24))

#echo "$USER has $DAYSLEFT left"

#Get email address
EMAIL="$(ipa user-show $USER | grep -i email | sed 's/^.*: //')"

# send out an email if it is less than or equal to the number of days left
if [ $DAYSLEFT -le $THENUMBEROFDAYS ];
then

# create the email content
echo "You are receiving this email because the password for your $USER account expires on $(date -d $EXPIRYDATE +%D). 
Policies require that all user accounts change their password every 60 days. 
Since your account requires you to have a password, you have to change it to continue to perform Admin functions. 
Please utilize the web gui access to change your password. 
Once logged in, in the upper right hand corner select your name, then change password.
If you become locked out, you will have to contact another admin to unlock your account." >> $USER.temp
echo " " >> $USER.temp
echo "Admin automation script" >> $USER.temp

# send the email out
 mailx -s "$USER Password is about to expire [DO_NOT_REPLY]" $EMAIL < $USER.temp

# delete content file
rm -rf $USER.temp
fi
done

#Destroy kinit
/usr/bin/kdestroy