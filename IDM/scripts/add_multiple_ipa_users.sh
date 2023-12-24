#!/bin/bash
########################################################
#Synopsis:
# Adds multiple "staged" users to ipa.

#How to use:
#Edit use file in this dir named: users_to_add.list
#Obtain Kerberos Credentials via "kinit {username}"
#Then run this script
########################################################

#Variables:
use_file=/usr/local/admin/users_to_add.list

########################################################
#DO NOT EDIT BELOW THIS#
egrep -v "^#|^$" "$use_file" | while read -r line; do

#while read line; do
# if grep -v "^#" "$line" ; then
  ipa stageuser-add $(echo $line | cut -f 1 -d " ") \
	--first=$(echo $line | cut -f 2 -d " ") \
	--last=$(echo $line | cut -f 3 -d " ") \
	--uid=$(echo $line | cut -f 4 -d " ") \
	--gidnumber=$(echo $line | cut -f 5 -d " ") \
	--title="$(echo $line | cut -f 6 -d " ")" \
	--random"
# fi
done #< "$use_file"
