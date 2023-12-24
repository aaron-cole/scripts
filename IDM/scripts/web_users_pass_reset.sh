#!/bin/bash

# open a kerberos ticket using keytab authentication if needed
/usr/bin/kinit host/idmserver.myidm.local@MYIDM.LOCAL -k -t /etc/krb5.keytab

# how many days before expiry? at which point will the password be reset
THENUMBEROFDAYS=1

#queries the ldap server for whatever group you want, or search parameters you want to use
# grepping memberUid for the group you want and piping to awk results in a list of users
USERLIST=$(ldapsearch -x -b cn=web_users,cn=groups,cn=compat,dc=myidm,dc=local | grep memberUid | awk '{print $2}')

# gets todays date in the same format as ipa
TODAYSDATE=$(date +"%Y%m%d")

# using date command to convert to a proper date format for the subtraction of days left
CALCTODAY=$(date -d "$TODAYSDATE" +%s)

# start the main loop
for USER in $USERLIST; do

# gets date, removes time uses cut to get only first 8 characters of date
 EXPIRYDATE=$(ipa user-show $USER --all | grep krbpasswordexpiration | awk '{print $2}' | cut -c 1-8)

# using date command to convert to a proper date format for the subtraction of days left
# All times are in secs to allow for roll over to new years
# Subtraction is done by seconds then converted back to days
 CALCEXPIRY=$(date -d "$EXPIRYDATE" +%s)
 SECSLEFT=$(expr $CALCEXPIRY - $CALCTODAY)
 DAYSLEFT=$((SECSLEFT/60/60/24))

# Reset password with 1 day or less left
 if [ $DAYSLEFT -le $THENUMBEROFDAYS ]; then

echo "$USER Password needs changed"
# ipa user-mod --random $USER

 fi
done
kdestroy