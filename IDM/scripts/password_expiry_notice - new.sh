#!/bin/bash
####Variables####
# how many days before expiry? at which point a single email should be sent out
THENUMBEROFDAYS=14

# Identified Groups with Passwords
GRPSwPass="admins"

# Keytab Principal to invoke
krb_princ="host/idmserver.myidm.local@MYIDM.LOCAL"

# Full dc of environment
DC_item="dc=myidm,dc=local"

####End of Variables####

# open a kerberos ticket using keytab authentication
/usr/bin/kinit -k -t /etc/krb5.keytab "$krb_princ"

#Start Loop for accounts with Pass
for GRP in $GRPSwPass; do

#queries the ldap server for whatever group you want, or search parameters you want to use
# grepping memberUid for the group you want and piping to awk results in a list of users
 USERLIST=$(ldapsearch -x -b cn=$GRP,cn=groups,cn=compat,$DC_item | grep memberUid | awk '{print $2}')

#If GRP is non-POSIX then we have to dive into the authenticated section
#This way is slow - that's the only reason it's not the main search
 if [ -z "$USERLIST" ]; then
  USERLIST=$(ldapsearch -Y GSSAPI -LLL -Q -b cn=$GRP,cn=groups,cn=accounts,$DC_item | grep "^member:" | awk '{print $2}'  | cut -f1 -d"," | cut -f2 -d"=")
 fi

# start the main loop
 for USER in $USERLIST; do

# gets todays date in the same format as ipa
  TODAYSDATE=$(date +"%Y%m%d")
  echo "Checking Expiry For $USER"

# gets date, removes time uses cut to get only first 8 characters of date
  EXPIRYDATE=$(ipa user-show $USER --raw --all | grep -i krbpasswordexpiration | awk '{print $2}' | cut -c 1-8)

# using date command to convert to a proper date format for the subtraction of days left
  CALCEXPIRY=$(date -d "$EXPIRYDATE" +%s)
  CALCTODAY=$(date -d "$TODAYSDATE" +%s)
  SECSLEFT=$(expr $CALCEXPIRY - $CALCTODAY)
  DAYSLEFT=$((SECSLEFT/60/60/24))

#Get email address
  EMAIL="$(ipa user-show $USER | grep -i email | sed 's/^.*: //')"

#If It's null send it to me
  if [ -z $EMAIL ]; then
   EMAIL="aaron.cole@dla.mil"
  fi

#uncomment to test
  echo "$USER with email $EMAIL has $DAYSLEFT left"

# send out an email if it is less than or equal to the number of days left
# and not a negative number (passed due) 
  if [ $DAYSLEFT -le $THENUMBEROFDAYS ] && [ $DAYSLEFT -ge 0 ]; then

# create the email content
   mailsubject="$USER Password is about to expire [DO_NOT_REPLY]"
   mailbody="You are receiving this email because the password for your $USER account expires on $(date -d $EXPIRYDATE +%D). Policies require that all user accounts change their password every 60 days. 

Since your account has been identified that you require a password to perform your job function it must be changed.  

If it is not changed with in $DAYSLEFT days, your account will be disabled.

If your account becomes disabled, you will have to submit a ticket to have your account unlocked.

After 30 days of your account being disabled it will be deleted."

# send the email out
   echo $mailbody | mailx -r admins@myidm.local -s "$mailsubject" $EMAIL

#   echo "NEED TO SEND EMAIL"
#   echo "Mail Subject - $mailsubject"
#   echo "Mail Body - $mailbody"


  fi
 done # end of For Users in groups
done # end of For Grps

#Destroy kinit
/usr/bin/kdestroy
