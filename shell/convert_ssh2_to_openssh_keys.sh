#!/bin/sh
#This will convert all ssh2 keys
# to openssh format and place them
# in .ssh/authorizedkeys files
# and change permissions as needed

for homedir in $(ls /home); do
#user=${homedir%?}
user=$homedir
homedir="/home/$homedir/"
usergrp=$(grep $user /etc/passwd | cut -f 4 -d :)
sshdir="$homedir.ssh"

#create .ssh dir
if [ ! -e $sshdir ]; then
 mkdir $sshdir
fi 
 
find $homedir.ssh2 -type f -name "*.pub" -exec /usr/bin/ssh-keygen -i -f {} >> $sshdir/authorizedkeys \;
  
 chown -R $user:$usergrp $sshdir
 chmod 700 $sshdir
 chmod 600 $sshdir/authorizedkeys
 
done
