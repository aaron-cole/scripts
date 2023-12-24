#!/bin/bash

# open a kerberos ticket using keytab authentication if needed
klist -s
if [[ $? -gt 0 ]]; then
/usr/bin/kinit admin@myidm.local -k -t /home/admin/.krb5/admin.keytab
fi

#variables
reportfile="/tmp/report.csv"
mailsubject="[DO NOT REPLY]IDM Host Lists"
mailbody="This is a review of IDM Hosts."
hostdn="cn=computers,cn=accounts,dc=myidm,dc=local"
echo "HostName,Description,Location,OS,HostGroups," > $reportfile

#echo "Please enter email recipients seperated by a space"
#read emaillist
emaillist="aaroncole@myidm.local"

hosts="$(ldapsearch -Y GSSAPI -b $hostdn | grep ^fqdn | awk '{print $2}' 2>/dev/null)" 

for host in $hosts; do
 desc="$(ipa host-show "$host" | grep "Description" | awk -F ":" '{print $2}' | sed 's/^ //g')"
 location="$(ipa host-show "$host" | grep "Location" | awk -F ":" '{print $2}' | sed 's/^ //g')"
 OS="$(ipa host-show "$host" | grep "Operating system" | awk -F ":" '{print $2}' | sed 's/^ //g')"
 Hgrps="$(ipa host-show "$host" | grep "Member of host-groups" | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,//g')"
 echo "$host, $desc, $location, $OS, $Hgrps" >> $reportfile

ipa host-show "$host" --all | egrep "Host name|Description|Location|Operating system|Member of host-groups" | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 'N;N;N;N;s/\n/,/g' >> $reportfile
done

echo $mailbody | mailx -s "$mailsubject" -a $reportfile $emaillist

rm $reportfile
kdestroy