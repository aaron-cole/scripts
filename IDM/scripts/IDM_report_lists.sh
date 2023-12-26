#!/bin/bash
############################################################
#
#  Synopsis: Script to Create a csv files for info from IDM
#            
#			#1 You must get Kerberos Credentials
#              first by using the kinit command.
#             
#			#2 Email receipients by be a list seperated
#			   by a space
#
############################################################
#setup
#Check if there is a $1

#check Kerberos credentials
klist -s
if [ "$?" == "1" ]; then
 echo "You must have Kerberos Credenitals"
 exit 1
fi

#Mail variables
mailsubject="[DO NOT REPLY]Review of Accounts"
mailbody="This is info from IDM"
emaillist="admin@myidm.local"

############################################################
##User Report
users="$(ipa user-find --all --raw |  grep "uid:" | sed 's/^.*uid: //g' | grep -v "^admin$")"
userreportfile="/tmp/users.csv"
echo "User login,Display name,Home directory,Login Shell,Email address,UID,GID,Groups" > $userreportfile

for user in $users; do  
 ipa user-show "$user" --all | egrep "User login|Display name|Home directory|Login shell|Email address|UID:|GID:|Member of groups" | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 'N;N;N;N;N;N;N;s/\n/,/g' >> $userreportfile
done

#Mail it out
echo $mailbody | mailx -s "$mailsubject" -a $userreportfile $emaillist
rm $userreportfile


############################################################
##User Group Report
usrgrps="$(ipa group-find | grep "Group name:"| sed 's/^.*Group name: //g'| egrep -v "^trust admins$|^editors$|^ipausers$")"
usrgrpreportfile="/tmp/usrgrps.csv"
echo "User Group,GID,Members" > $usrgrpreportfile

for usrgrp in $usrgrps; do  
 ipa group-show "$usrgrp" | egrep "Group name|GID|Member users" | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 'N;N;s/\n/,/g' >> $usrgrpreportfile
done

#Mail it out and remove
echo $mailbody | mailx -s "$mailsubject" -a $usrgrpreportfile $emaillist
rm $usrgrpreportfile


############################################################
##Host Report
hosts="$(ipa host-find --all | grep "Host name:" | sed 's/^.*Host name: //g')"
hostreportfile="/tmp/hosts.csv"
echo "Host Name,Location,OS,Member of Groups" > $hostreportfile

for host in $hosts; do
 ipa host-show "$host" --all | egrep "Host name:|Location:|Operating system:|Member of host-groups:"| awk -F ":" '{print $2}' | sed 's/^ //g' | sed 'N;N;N;s/\n/,/g' >> $hostreportfile
done

#Mail it out and remove
echo $mailbody | mailx -s "$mailsubject" -a $hostreportfile $emaillist
rm $hostreportfile

############################################################
##HostGrp Report
hostgrps="$(ipa hostgroup-find | grep "Host-group:"| sed 's/^.*Host-group: //g')"
hostgrpreportfile="/tmp/hostgrp.csv"
echo "Host Group,Members" > $hostgrpreportfile

for hostgrp in $hostgrps; do
 ipa hostgroup-show "$hostgrp" --all | egrep "Host-group:|Member hosts:"| awk -F ":" '{print $2}' | sed 's/^ //g' | sed 'N;s/\n/,/g' >> $hostgrpreportfile
done

#Mail it out and remove
echo $mailbody | mailx -s "$mailsubject" -a $hostgrpreportfile $emaillist
rm $hostgrpreportfile

############################################################
##HBAC Reports
hbacrules="$(ipa hbacrule-find | grep "Rule name:"| sed 's/^.*Rule name: //g')"
hbacreportfile="/tmp/hbac_report.csv"
echo "Rule,Enabled,Users,User Groups,Hosts,Host Groups" > $hbacreportfile

for hbacrule in $hbacrules; do 
 startline="$(ipa hbacrule-show "$hbacrule" --all | egrep "Rule name|Enabled" | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 'N;s/\n/,/g')"

#Lets look at each rule and user/usergroups/all
 usrtestrule="$(ipa hbacrule-show "$hbacrule" --all | grep "User")"
 
 case $(echo "$usrtestrule" | wc -l) in
 	1) case $(echo "$usrtestrule") in
 			*Users:*) userline="$startline,"$(echo $usrtestrule | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')",none"
 			;;
 			*category:*) userline="$startline,ALL,ALL,"
 			;;
 			*Groups:*) userline="$startline,none,"$(echo $usrtestrule | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')""
 			;;
 		 esac
 	;;
 	2) userline="$startline,"$(ipa hbacrule-show $hbacrule --all | grep User | sed 's/,/;/g' | awk -F ":" '{print $2}'| sed 's/^ //g' | sed 'N;s/\n/,/g')
 	;; 
 esac

#Lets look at each rule and host/hostgroups/all and add the the userline
 hsttestrule="$(ipa hbacrule-show "$hbacrule" --all | grep "Host")"
 case $(echo "$hsttestrule" | wc -l) in
 	1) case $(echo "$hsttestrule") in
 			*Hosts:*) hostline="$userline,"$(echo $hsttestrule | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')",none"
 			;;
 			*category:*) hostline="$userline,ALL,ALL"
 			;;
 			*Groups:*) hostline="$userline,none,"$(echo $hsttestrule | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')""
 			;;
 		 esac
 	;;
 	2) hostline="$userline,"$(ipa hbacrule-show $hbacrule --all | grep Host | sed 's/,/;/g' | awk -F ":" '{print $2}'| sed 's/^ //g' | sed 'N;s/\n/,/g')
 	;; 
 esac
 
 echo "$hostline" >> $hbacreportfile
done

#Mail it out and remove
echo $mailbody | mailx -s "$mailsubject" -a $hbacreportfile $emaillist
rm $hbacreportfile

############################################################
##SudoCommand Reports

#Sudo Commands
sudocmdsreportfile="/tmp/sudo_cmd_report.csv"
echo "Sudo Command" > $sudocmdsreportfile
ipa sudocmd-find | grep "Sudo Command"| awk -F ":" '{print $2}' | sed 's/^ //g'  >> $sudocmdsreportfile

#Sudo Command Groups
sudocmdgrpreportfile="/tmp/sudo_cmd_grps_report.csv"
echo "Sudo Group,Commands" > $sudocmdgrpreportfile
sudocmdgrps="$(ipa sudocmdgroup-find | grep "Sudo Command Group:"| awk -F ":" '{print $2}' | sed 's/^ //g')"

for sudocmdgrp in $sudocmdgrps; do
 ipa sudocmdgroup-show "$sudocmdgrp" --all | egrep "Sudo Command Group:|Member Sudo commands:"| awk -F ":" '{print $2}' | sed 's/^ //g' | sed 'N;s/\n/,/g' >> $sudocmdgrpreportfile
done

#Mail it out and remove
echo $mailbody | mailx -s "$mailsubject" -a $sudocmdsreportfile -a $sudocmdgrpreportfile $emaillist
rm $sudocmdsreportfile
rm $sudocmdgrpreportfile

############################################################
##Sudo Rules
sudorules="$(ipa sudorule-find | grep "Rule name:"| sed 's/^.*Rule name: //g')"
sudoreportfile="/tmp/sudo_report.csv"
echo "Rule name,Enabled,Sudo Order,Sudo Options,Users,User Groups,Local Users,Hosts,Host Groups,External Hosts,Sudo Commands,Sudo Command Groups,RunAs User, RunAs User Groups, RunAs Local Users" > $sudoreportfile

for sudorule in $sudorules; do 
 startline="$(ipa sudorule-show "$sudorule" --all | egrep "Rule name|Enabled" | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 'N;s/\n/,/g')"
 
#Sudo Order
sudoorder="$startline,"$(ipa sudorule-show "$sudorule" --all | grep "Sudo order:" | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')""

#Sudo options
sudooptions="$sudoorder,"$(ipa sudorule-show "$sudorule" --all | grep "Sudo Option:" | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')""

#Sudo User/Groups 
 sudousrtestrule="$(ipa sudorule-show "$sudorule" --all | grep "User"| egrep -v "RunAs|External|Description")"
 case $(echo "$sudousrtestrule" | wc -l) in
 	1) case $(echo "$sudousrtestrule") in
 			*Users:*) sudousrs="$sudooptions,"$(echo $sudousrtestrule | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')",none"
 			;;
 			*category:*) sudousrs="$sudooptions,ALL,ALL"
 			;;
 			*Groups:*) sudousrs="$sudooptions,none,"$(echo $sudousrtestrule | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')""
 			;;
 			*) sudousrs="$sudooptions,none,none"
 		 	;;
 		 esac
 	;;
 	2) sudousrs="$sudooptions,"$(ipa sudorule-show "$sudorule" --all | grep "User"| egrep -v "RunAs|External|Description" | sed 's/,/;/g' | awk -F ":" '{print $2}'| sed 's/^ //g' | sed 'N;s/\n/,/g')
 	;; 
 esac

#Sudo External Users
sudouserexternal="$sudousrs,"$(ipa sudorule-show "$sudorule" --all | grep "External User:" | grep -v "RunAs" | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')""

#Sudo Hosts/Groups 
 sudohosttestrule="$(ipa sudorule-show "$sudorule" --all | grep "Host"| egrep -v "RunAs|External")"
 case $(echo "$sudohosttestrule" | wc -l) in
 	1) case $(echo "$sudohosttestrule") in
 			*Hosts:*) sudohosts="$sudouserexternal,"$(echo $sudohosttestrule | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')",none"
 			;;
 			*category:*) sudohosts="$sudouserexternal,ALL,ALL"
 			;;
 			*Groups:*) sudohosts="$sudouserexternal,none,"$(echo $sudohosttestrule | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')""
 			;;
 			*) sudohosts="$sudouserexternal,none,none"
 		 	;;
 		 esac
 	;;
 	2) sudohosts="$sudouserexternal,"$(ipa sudorule-show "$sudorule" --all | grep "Host"| egrep -v "RunAs|External" | sed 's/,/;/g' | awk -F ":" '{print $2}'| sed 's/^ //g' | sed 'N;s/\n/,/g')
 	;; 
 esac

#Sudo External Hosts
sudohostexternal="$sudohosts,"$(ipa sudorule-show "$sudorule" --all | grep "External host:" | grep -v "RunAs" | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')""
 
#Sudo Commands
 sudocmdstestrule="$(ipa sudorule-show "$sudorule" --all | grep "Command" | grep -v "Description:")"
 case $(echo "$sudocmdstestrule" | wc -l) in
 	1) case $(echo "$sudocmdstestrule") in
 			*Commands:*) sudocmds="$sudohostexternal,"$(echo $sudocmdstestrule | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')",none"
 			;;
 			*category:*) sudocmds="$sudohostexternal,ALL,ALL"
 			;;
 			*Groups:*) sudocmds="$sudohostexternal,none,"$(echo $sudocmdstestrule | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')""
 			;;
 			*) sudocmds="$sudohostexternal,none,none"
 		 	;;
 		 esac
 	;;
 	2) sudocmds="$sudohostexternal,"$(ipa sudorule-show "$sudorule" --all | grep "Command" | grep -v "Description:" | sed 's/,/;/g' | awk -F ":" '{print $2}'| sed 's/^ //g' | sed 'N;s/\n/,/g')
 	;; 
 esac

#Sudo RunAs Users/Grps
 sudorunastestrule="$(ipa sudorule-show "$sudorule" --all | grep "RunAs" | grep "User" | grep -v "External")"
 case $(echo "$sudorunastestrule" | wc -l) in
 	1) case $(echo "$sudorunastestrule") in
 			*Groups*) sudorunas="$sudocmds,none,"$(echo $sudorunastestrule | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')""
 			;;
 			*Users:*) sudorunas="$sudocmds,"$(echo $sudorunastestrule | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')",none"
 			;;
 			*category:*) sudorunas="$sudocmds,root,root"
 			;;
 		 	*) sudorunas="$sudocmds,none,none"
 		 	;;
 		 	esac 
 	;;
 	2) sudorunas="$sudocmds,"$(ipa sudorule-show "$sudorule" --all |  grep RunAs | grep User | grep -v External | sed 's/,/;/g' | awk -F ":" '{print $2}'| sed 's/^ //g' | sed 'N;s/\n/,/g')
 	;;
 esac

#Sudo External RunAs
 sudoexrunastestrule="$(ipa sudorule-show "$sudorule" --all | grep "RunAs External User:")"
 case $(echo "$sudoexrunastestrule" | wc -l) in
 	1) sudoexrunas="$sudorunas,"$(ipa sudorule-show "$sudorule" --all | grep "RunAs External User:" | awk -F ":" '{print $2}' | sed 's/^ //g' | sed 's/,/;/g')""
 	;;
 	*) sudoexrunas="$sudorunas,none"
 	;;
 esac

 echo "$sudoexrunas" >> $sudoreportfile
done

echo $mailbody | mailx -s "$mailsubject" -a $sudoreportfile $emaillist

rm $sudoreportfile
