#!/bin/bash

myusrgroups="$(ipa group-find | grep "Group name:" | sed 's/^.*name: //g')"

echo "User Group;Description;Member Users;Sudo Rules;HBAC Rules" > usergroups.csv

for myusrgroup in $myusrgroups; do
  ipdesc="$(ipa group-show $myusrgroup | grep "Description:" | sed 's/^.*Description: //g')"
  ipusers="$(ipa group-show $myusrgroup | grep "Member users:" | sed 's/^.*users: //g')"
  ipsudo="$(ipa group-show $myusrgroup | grep "Member of Sudo rule:" | sed 's/^.*rule: //g')"
  iphbac="$(ipa group-show $myusrgroup | grep "Member of HBAC rule:" | sed 's/^.*rule: //g')"
  echo "$myusrgroup;$ipdesc;$ipusers;$ipsudo;$iphbac" >> usergroups.csv
done