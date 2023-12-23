#!/bin/sh
#This will convert all ssh2 keys
# to openssh format and place them
# in .ssh/authorizedkeys files
# and change permissions as needed

for homedir in $(ls /home); do
user=${homedir%?}
#user=$homedir
fullpathhd="/home/$homedir"
usergrp=$(grep $user /etc/passwd | cut -f 4 -d :)
sshdir="$fullpathhd.ssh"

#create .ssh dir
if [ ! -e $sshdir ]; then
 mkdir $sshdir
fi 
 
find $fullpathhd.ssh2 -type f -name "*.pub" -exec /usr/bin/ssh-keygen -i -f {} >> $sshdir/authorized_keys \;
  
 chown -R $user:$usergrp $sshdir
 chmod 700 $sshdir
 chmod 600 $sshdir/authorized_keys
 
done