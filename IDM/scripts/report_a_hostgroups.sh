#!/bin/bash

myhostgroups="$(ipa hostgroup-find | grep "Host-group:" | sed 's/^.*group: //g')"

echo "Host Group Name;Member Servers;Sudo Rules;HBAC Rules" > Hostgroups.csv

for myhostgroup in $myhostgroups; do
  iphostgrp="$(ipa hostgroup-show $myhostgroup | grep "Host-group:" | sed 's/^.*group: //g')"
  iphosts="$(ipa hostgroup-show $myhostgroup | grep "Member hosts:" | sed 's/^.*hosts: //g')"
  ipsudo="$(ipa hostgroup-show $myhostgroup | grep "Member of Sudo rule:" | sed 's/^.*rule: //g')"
  iphbac="$(ipa hostgroup-show $myhostgroup | grep "Member of HBAC rule:" | sed 's/^.*rule: //g')"
  echo "$iphostgrp;$iphosts;$ipsudo;$iphbac" >> Hostgroups.csv
done