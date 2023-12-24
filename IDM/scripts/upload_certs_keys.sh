#!/bin/bash
########################################################
#Synopsis:
# Adds multiple "Certificates" to users in ipa.

#How to use:
#1. Obtain Kerberos Credentials via "kinit {username}"
#2. Have each cert labeled as username.cert inside the
#   certs folder.
#3. Certificate Format is usually raw DER from windows
#   Machines.  So use that format. Don't know cat the
#   cert file - if gobbly goop then it's raw DER.  
#Then run this script
########################################################

#Variables:
use_dir="./certs"

########################################################
#DO NOT EDIT BELOW THIS#

for f in $use_dir/*.cer; do

#get username
  username="$(echo $f | cut -f 3 -d "/" | cut -f 1 -d ".")"

#get pubkey (pem format) from cert
  openssl x509 -in $f -inform der -noout -pubkey > $use_dir/$username.pubkey

#transform into rsakey
  rsakey="$(ssh-keygen -i -m PKCS8 -f $use_dir/$username.pubkey)"

#upload cert  
#ipa user-add-cert $username --certificate="$(cat $use_dir/$f | base64 -w 0)"
#upload rsakey and cert
ipa user-mod --sshpubkey="$(echo $rsakey)" --certificate="$(cat $f | base64 -w 0)" $username  
done
