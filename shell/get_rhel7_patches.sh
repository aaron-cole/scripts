#!/bin/bash

#Check if running as root
if [ "$(id -u)" != "0" ]; then
	echo "This has to be run as root" 1>&2
	exit 1
fi

#Get RHEL OS Version
if ! grep "7." /etc/redhat-release >> /dev/null; then
 echo "This can only be ran on a RHEL7 Machine"
 exit 1
fi

#Just to make sure you are in the correct directory
cd /reposync

#List of Repositorys to sync
REPOLIST="rhel-x86_64-server-7-thirdparty-oracle-java rhel-x86_64-server-7-rhdirserv-10 rhel-x86_64-server-extras-7 rhel-x86_64-server-ha-7 rhel-x86_64-server-optional-7 rhel-x86_64-server-rs-7 rhel-x86_64-server-supplementary-7 rhn-tools-rhel-x86_64-server-7 rhel-x86_64-server-7"

#Need to check and make sure we have all the channels
#To be packages from
for repo in $REPOLIST; do
 yum repolist $repo > ./repolist
 if [ "$(grep "^repolist: " ./repolist)" ] && [ "$(grep "^repolist: " ./repolist | cut -f 2 -d " " | sed 's/,//g' )" -gt 0 ]; then
  echo "$repo is enabled and available to be syncd"
 else
  echo "$repo is not assigned to server"
  echo "Assign to server then re-run script"
  exit 1
 fi
done

#Lets start this sync
#The "-n" only syncs new package
#So we won't get old stuff
for repo in $REPOLIST; do
 reposync --gpgcheck -l -n --repoid=$repo --download_path=/reposync
done

#Lets tar up the stuff
#Add some permissions to download
for item in *; do

#Going to skip anything not a directory
#Since our syncs all go into directories
 if [ -f "$item" ]; then
  continue 
 fi
 
#Tar it up and change perms on tarball 
 tar cvzf ./$item.tar.gz ./$item
 chmod 644 ./$item.tar.gz
done

echo ""

#Lets split big files that won't fit on DVDs
for tarball in *.tar.gz; do
 if [ "$(stat -c%s $tarball)" -gt 4367966547 ]; then
  echo "Splitting $tarball since it's over 4.36Gig and won't fit on a DVD"
  echo "To combine use the following command:"
  echo "cat $tarball.part-* | tar xvz"
  split -b 1G $tarball "$tarball.part-"
   if [ $? -eq 0 ]; then
   	rm -rf $tarball
   fi
 fi
done

#Cleanup
#Remove directories since we have tarballs
for DIR in *; do
 if [ -d "$DIR" ]; then
  rm -rf ./$DIR
 fi
done

rm -rf ./repolist
echo ""
echo "Tarballs are ready to be copied to your PC for burning"
echo "You may need to put SELINUX in permissive mode to copy"
