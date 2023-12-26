#!/bin/bash

myhbacrules="$(ipa hbacrule-find | grep "Rule name:" | sed 's/^.*name: //g')"

echo "HBAC Rule;Enabled;UserGroups;Hostgroups" > hbacrules.csv

for myhbacrule in $myhbacrules; do
  ipenabled="$(ipa hbacrule-show $myhbacrule | grep "Enabled:" | sed 's/^.*Enabled: //g')"
  ipusrgrps="$(ipa hbacrule-show $myhbacrule | grep "User Groups:" | sed 's/^.*Groups: //g')"
  iphostgrps="$(ipa hbacrule-show $myhbacrule | grep "Host Groups:" | sed 's/^.*Groups: //g')"
  echo "$myhbacrule;$ipenabled;$ipusrgrps;$iphostgrps" >> hbacrules.csv
done