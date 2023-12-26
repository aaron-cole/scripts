#!/bin/bash

mysudorules="$(ipa sudorule-find | grep "Rule name:" | sed 's/^.*name: //g')"

echo "SUDO Rule;Enabled;UserGroups;Hostgroups;Run As Users" > sudorules.csv

for mysudorule in $mysudorules; do
  ipenabled="$(ipa sudorule-show $mysudorule | grep "Enabled:" | sed 's/^.*Enabled: //g')"
  ipusrgrps="$(ipa sudorule-show $mysudorule | grep "User Groups:" | sed 's/^.*Groups: //g')"
  iphostgrps="$(ipa sudorule-show $mysudorule | grep "Host Groups:" | sed 's/^.*Groups: //g')"
  iprunas="$(ipa sudorule-show $mysudorule | grep "RunAs External User:" | sed 's/^.*User: //g')"
  echo "$mysudorule;$ipenabled;$ipusrgrps;$iphostgrps;$iprunas" >> sudorules.csv
done