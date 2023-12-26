#!/bin/bash
echo "Username;First Name;Last Name;Email Address;Disabled;Certificate Subject Alternative Name;Certifcate Expiration;IDM User Groups" >> IDM_users.csv        

for user in $(ipa user-find | grep "User login:" | sed 's/^.*: //g'); do       
  usr_name="$(ipa user-show $user | grep "User login:" | sed 's/^.*: //g')"    
  fstname="$(ipa user-show $user | grep "First name:" | sed 's/^.*: //g')"     
  lstname="$(ipa user-show $user | grep "Last name:" | sed 's/^.*: //g')"      
  emailaddr="$(ipa user-show $user | grep "Email address:" | sed 's/^.*: //g')"
  useripagrps="$(ipa user-show $user | grep "Member of groups: " | sed 's/^.*: //g')"
  disablestatus="$(ipa user-show $user | grep "Account disabled: " | sed 's/^.*://g')"
  if ! ipa user-show $user | grep "Certificate" >> /dev/null 2>&1; then        
    sanname="No Cert"
    certenddate="No Cert"
  else
    ipa user-show $user | grep "Certificate" | sed 's/^.*Certificate: //g' | sed 's/^/-----BEGIN CERTIFICATE-----\n/g' >/tmp/test.cer                          
    echo "-----END CERTIFICATE-----" >> /tmp/test.cer                          
    certenddate="$(openssl x509 -in /tmp/test.cer -noout -enddate)"            
    sanname="$(certtool -i --infile /tmp/test.cer | grep "otherName ASCII: ..[mM]" | sed 's/^.*otherName ASCII: ..//g' )"                                      
    if [ -z $sanname ]; then
      sanname="NON ALT"
    fi

    echo "$usr_name;$fstname;$lstname;$emailaddr;$disablestatus;$sanname;$certenddate;$useripagrps" >> IDM_users.csv
  fi
done