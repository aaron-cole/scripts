#!/bin/bash

##Only adjustment really needed
groups_to_go_thru="grp1 grp2 grp3"

##Don't Edit below
##Function for heavy lifting
function reset_svcacct_passwd_random () {
  if [ -z "$*" ]; then
    return
  fi
  
  for srv_name in $*; do
    openssl rand -base64 32 | passwd --stdin $srv_name
    #echo "$srv_name" - needs changed
  done
}

###Start the script
for svcacct_grp in $groups_to_go_thru; do
  svcacct_list="$(lid -gn $svcacct_grp)"
  reset_svcacct_passwd_random $svcacct_list
done
