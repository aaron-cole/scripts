#!/bin/bash

# open a kerberos ticket using keytab authentication if needed
klist -s
if [[ $? -gt 0 ]]; then
/usr/bin/kinit admin@MYIDM.LOCAL -k -t /home/admin/.krb5/admin.keytab
fi

# how many days before expiry? at which point will the password be reset

THENUMBEROFDAYS=1

#queries the ldap server for whatever group you want, or search parameters you want to use
# grepping memberUid for the group you want and piping to awk results in a list of users
USERLIST=$(ldapsearch -x -b cn=idmusers,cn=groups,cn=compat,dc=myidm,dc=local | grep memberUid | awk '{print $2}')

# start the main loop
for USER in $USERLIST;
do
# gets todays date in the same format as ipa
TODAYSDATE=$(date +"%Y%m%d")

# gets date, removes time uses cut to get only first 8 characters of date
EXPIRYDATE=$(ipa user-show $USER --all | grep krbpasswordexpiration | awk '{print $2}' | cut -c 1-8)

# using date command to convert to a proper date format for the subtraction of days left
CALCEXPIRY=$(date -d "$EXPIRYDATE" +%j)
CALCTODAY=$(date -d "$TODAYSDATE" +%j)
DAYSLEFT=$(expr $CALCEXPIRY - $CALCTODAY)

# Reset password with 1 day or less left
if [ $DAYSLEFT -le $THENUMBEROFDAYS ];
then

#echo "$USER Password needs changed"
ipa user-mod --random $USER

fi
done
kdestroy