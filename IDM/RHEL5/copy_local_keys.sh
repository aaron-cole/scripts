#!/bin/bash
for f in $(ls /home); do
if [ ! -d /etc/ssh/keys/$f ]; then
mkdir /etc/ssh/keys/$f
 	 cp /home/$f/.ssh/* /etc/ssh/keys/$f
   chown -R $f /etc/ssh/keys/$f
   chmod -R 600 /etc/ssh/keys/$f
   chmod 700 /etc/ssh/keys/$f
 fi
done
