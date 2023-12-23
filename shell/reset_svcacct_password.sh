#!/bin/bash

##Only adjustment really needed
groups_to_go_thru="grp1 grp2 grp3"

##Don't Edit below

##Time stuff for comparision
epochdate_in_seconds="$(date +%s)"
let epochdate_in_days=$epochdate_in_seconds/86400

##Function for heavy lifting
function reset_svcacct_passwd_random () {
  if [ -z "$*" ]; then
    return
  fi
  
  for srv_name in $*; do
    svcacct_last_pass_change="$(grep ^$srv_name: /etc/shadow | cut -f 3 -d:)"
    let do_i_change=$svcacct_last_pass_change+29
    if [ "$epochdate_in_days" > "$do_i_change" ]; then
      openssl rand -base64 32 | passwd --stdin $srv_name
      #echo "$srv_name" - needs changed
    fi
    unset svcacct_last_pass_change
  done
}

###Start the script
for svcacct_grp in $groups_to_go_thru; do
  svcacct_list="$(lid -gn $svcacct_grp)"
  reset_svcacct_passwd_random $svcacct_list
done
