#!/bin/bash
for user in $(ipa user-find | grep "User login:" | sed 's/^.*: //g'); do
 if ! ipa user-show $user | grep "Certificate" >> /dev/null 2>&1; then
  disablestatus="$(ipa user-show $user | grep "Account disabled: ")"
  echo "$user - No Cert attached - $disablestatus" >> no-cert-list
 else
  ipa user-show $user | grep "Certificate" | sed 's/^.*Certificate: //g' | sed 's/^/-----BEGIN CERTIFICATE-----\n/g' >/tmp/test.cer
  echo "-----END CERTIFICATE-----" >> /tmp/test.cer
  certenddate="$(openssl x509 -in /tmp/test.cer -noout -enddate)"
  echo "$user - $certenddate" >> expiration-list
  if openssl x509 -in /tmp/test.cer -noout -text | grep -i "Subject:" | grep -i "CN=alt." >> /dev/null; then 
   echo "$user - ALT Cert">> ALT-list
  elif openssl x509 -noout -in /tmp/test.cer -text | grep -A1 -i "X509v3 Extended Key Usage:" | grep -i "e-mail" >> /dev/null; then
   echo "$user - email" >> email-cert-list
  elif openssl x509 -noout -in /tmp/test.cer -text | grep -A1 -i "X509v3 Extended Key Usage:" >> /dev/null; then
   echo "$user - PIV" >> PIV-user-list
  else
   emailaddress="$(ipa user-show $user | grep "Email address: ")"
   echo "$user - $emailaddress" >> non-alt_piv-list
  fi
 fi
done