#!/bin/bash

EMAILLIST="admin@myidm.local"
MAILBODY="/tmp/msg"
STOP=0
CHKTIME=0
SENDMAIL=0

fnrestart ()
{
echo $(date) >> $MAILBODY
if ipactl status | grep "STOPPED" >> $MAILBODY; then
 SENDMAIL=1
 echo "Above Services are down" >> $MAILBODY
 echo "" >> $MAILBODY
 echo "Attempting Restart" >> $MAILBODY
 ipactl restart >> $MAILBODY
 echo "" >> $MAILBODY
fi
}

fnremovemailbody ()
{
if [ -e $MAILBODY ]; then
 rm -rf "$MAILBODY"
fi
}

#Remove /tmp/msg if it exists
fnremovemailbody

while [ $STOP -eq 0 ]; do
 fnrestart
 CHKTIME=$((CHKTIME + 1))
 if [ ipactl status | grep "STOPPED" ] && [ "$CHKTIME" -lt 5 ] ; then
  continue
 elif  [ ipactl status | grep "STOPPED" ] && [ "$CHKTIME" -eq 5 ] ; then
  STOP=1
  MAILSUB="UNABLE TO START IDM SERVICES"
 else
  STOP=1
  MAILSUB="IDM SERVICES WERE RESTARTED"
 fi
done 

#Send Mail
if [ $SENDMAIL -eq 1 ]; then
 echo "$MAILBODY" | mailx -s "$MAILSUB" $EMAILLIST
fi
	
#Remove /tmp/msg if it exists
fnremovemailbody