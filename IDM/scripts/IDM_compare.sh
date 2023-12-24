#!/bin/bash

#check Kerberos credentials
klist -s
if [ "$?" == "1" ]; then
 echo "You must have Kerberos Credenitals"
 kinit
fi

#Current Lists
CUSERS="/home/aaroncole/IDM_Changes/lists/current_users"
CHOSTS="/home/aaroncole/IDM_Changes/lists/current_hosts"
CUSRGRPS="/home/aaroncole/IDM_Changes/lists/current_usergrps"
CUSRGRPSMEM="/home/aaroncole/IDM_Changes/lists/current_usergrpsmem"
CHGRP="/home/aaroncole/IDM_Changes/lists/current_hostgrps"
CHGRPMEM="/home/aaroncole/IDM_Changes/lists/current_hostgrpsmem"
CHBAC="/home/aaroncole/IDM_Changes/lists/current_hbac"
#CSCG="/home/aaroncole/IDM_Changes/lists/current_sudo_cmdgrps"
#CSUCMDS="/home/aaroncole/IDM_Changes/lists/current_sudo_commands"
#CSUDO="/home/aaroncole/IDM_Changes/lists/current_sudo_rules"


#New Lists
NUSERS="/home/aaroncole/IDM_Changes/lists/new_users"
NHOSTS="/home/aaroncole/IDM_Changes/lists/new_hosts"
NUSRGRPS="/home/aaroncole/IDM_Changes/lists/new_usergrps"
NUSRGRPMEM="/home/aaroncole/IDM_Changes/lists/new_usergrpsmem"
NHGRP="/home/aaroncole/IDM_Changes/lists/new_hostgrps"
NHGRPMEM="/home/aaroncole/IDM_Changes/lists/new_hostgrpsmem"
NHBAC="/home/aaroncole/IDM_Changes/lists/new_hbac"
#NSCG="/home/aaroncole/IDM_Changes/lists/new_sudo_cmdgrps"
#NSUCMDS="/home/aaroncole/IDM_Changes/lists/new_sudo_commands"
#NSUDO="/home/aaroncole/IDM_Changes/lists/new_sudo_rules"


#Others
UserChanges="/home/aaroncole/IDM_Changes/UserChanges.csv"
HostChanges="/home/aaroncole/IDM_Changes/HostChanges.csv"
UserGroupChanges="/home/aaroncole/IDM_Changes/UserGroupChanges.csv"
HostGroupChanges="/home/aaroncole/IDM_Changes/HostGroupChanges.csv"
HBACChanges="/home/aaroncole/IDM_Changes/HBACChanges.csv"

###Get New information from IDM
ipa user-find --raw | egrep "uid:" | awk '{print $2}' > $NUSERS 
ipa host-find | grep "Host name:" | awk '{print $3}' > $NHOSTS
ipa group-find | grep "Group name" | awk '{print $3}' > $NUSRGRPS
for grpname in $(cat $NUSRGRPS); do
	fileline="$grpname,"
	fileline+="$(ipa group-show $grpname | egrep "Member users:" | awk -F: '{print $2}' | sed 's/,//g' | sed 's/^ //g')"
	echo "$fileline" >> $NUSRGRPMEM
done
ipa hostgroup-find | grep "Host-group:" | awk '{print $2}' > $NHGRP
for hgrpname in $(cat $NHGRP); do
	fileline="$hgrpname,"
	fileline+="$(ipa hostgroup-show $hgrpname | egrep "Member hosts:" | awk -F: '{print $2}' | sed 's/,//g' | sed 's/^ //g')"
	echo "$fileline" >> $NHGRPMEM
done
ipa hbacrule-find | grep "Rule name:" | awk '{print $2}' > $NHBAC

###Setup CSV Files to be emailed
echo "New/Remove,User login,First Name,Last Name,UID,GID,Email address,Job Title" > $UserChanges
echo "New/Remove,Host Name,Description,Enrolled" > $HostChanges
echo "Change,Group Name,GID,Members" > $UserGroupChanges
echo "Change,Host Group Name,Members" > $HostGroupChanges

###NEED TO LOOK AT ", " removing from files
###Need to look at "description missing from hosts"
###Don't forget to update Current lists with new
#-----------------------------------------------
#-----------------------------------------------
#USER CHANGES#
#New Users
for nuser in $(cat $NUSERS); do 
 if ! grep "^$nuser$" $CUSERS >>/dev/null; then 
  newline="New,$nuser,"
#  newline+="$(ipa user-find --all $nuser | egrep "First name| Last name|UID:|GID:|Email address:|Job Title:"| awk -F: '{print $2","}')"
  newline+="$(ipa user-show $nuser | egrep "First name| Last name|UID:|GID:|Email address:|Job Title:"| awk -F: '{print $2","}')"
	echo $newline >> $UserChanges
fi; done

#Removed Users
for cuser in $(cat $CUSERS); do 
 if ! grep "^$cuser$" $NUSERS >>/dev/null; then 
  echo "Remove,$cuser," >> $UserChanges
fi; done

#-----------------------------------------------
#-----------------------------------------------
#HOST CHANGES#
#New Hosts
for nhost in $(cat $NHOSTS); do 
 if ! grep "^$nhost$" $CHOSTS >>/dev/null; then 
  newline="New,$nhost,"
  newline+="$(ipa host-show $nhost | egrep "Description:|Keytab:" | awk -F: '{print $2","}')"
	echo $newline >> $HostChanges
fi; done

#Removed Hosts
for chost in $(cat $CHOSTS); do 
 if ! grep "^$chost$" $NHOSTS >>/dev/null; then 
  echo "Remove,$chost," >> $HostChanges
fi; done

#-----------------------------------------------
#-----------------------------------------------
#UserGroup CHANGES#
#New Groups
for nusrgrp in $(cat $NUSRGRPS); do 
 if ! grep "^$nusrgrp$" $CUSRGRPS >>/dev/null; then 
  newline="New Group,$nusrgrp,"
  newline+="$(ipa group-show $nusrgrp | egrep "GID:" | awk -F: '{print $2","}')"
  newline+="$(ipa group-show $nusrgrp | egrep "Member users:" | awk -F: '{print $2}' | sed 's/,//g')"
	echo $newline >> $UserGroupChanges
 else
#Now we check member changes because the group exists
  newline="$(grep "^$nusrgrp," $NUSRGRPMEM)"
  curline="$(grep "^$nusrgrp," $CUSRGRPMEM)"
  if [ "$newline" != "$curline" ]; then
	 grpgid="$(ipa group-show $nusrgrp | egrep "GID:" | awk -F: '{print $2}' | sed 's/^ //g')"
   echo "Members Changed,$newline" | sed 's/'"$f"',/'"$f"','"$grpgid"',/g' >> $UserGroupChanges
  fi  
fi;done

#Removed Groups
for cusrgrp in $(cat $CUSRGRPS); do 
 if ! grep "^$cusrgrp$" $NUSRGRPS >>/dev/null; then 
  echo "Removed,$cusrgrp," >> $UserGroupChanges
fi; done

#-----------------------------------------------
#-----------------------------------------------
#HostGroup CHANGES#
#New Groups
for nhgrp in $(cat $NHGRP); do 
 if ! grep "^$nhgrp$" $CHGRP >>/dev/null; then 
  newline="New HostGroup,$nhgrp,"
  newline+="$(ipa hostgroup-show $nhgrp | egrep "Member hosts:" | awk -F: '{print $2}' | sed 's/,//g')"
	echo $newline >> $HostGroupChanges
 else
#Now we have to check member changes because the group exists
  newline="$(grep "^$nhgrp," $NHGRPMEM)"
  curline="$(grep "^$nhgrp," $CHGRPMEM)"
  if [ "$newline" != "$curline" ]; then
	 echo "Members Changed,$newline" >> $HostGroupChanges
  fi  
fi;done

#Removed Groups
for chgrp in $(cat $CHGRP); do 
 if ! grep "^$chgrp$" $NHGRP >>/dev/null; then 
  echo "Removed,$chgrp," >> $HostGroupChanges
fi; done
  	
#-----------------------------------------------
#-----------------------------------------------
#HBAC Rule CHANGES#
#New Rules
for nhbac in $(cat $NHBAC); do 
 if ! grep "^$nhbac$" $CHBAC >>/dev/null; then 
  newline="New HostGroup,$nhbac,"
  newline+="$(ipa hostgroup-show $nhbac | egrep "Member hosts:" | awk -F: '{print $2}' | sed 's/,//g')"
	echo $newline >> $HBACChanges
 else
#Since Rule exists lets look at attributes

fi;done

#Removed Rules
for chbac in $(cat $CHBAC); do 
 if ! grep "^$chbac$" $NHBAC >>/dev/null; then 
  echo "Removed,$chbac," >> $HBACChanges
fi; done


##Not Ready to mail
