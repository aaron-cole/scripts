#!/bin/bash

#Only root can run this
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#If cron.allow doesn't exist
if [[ ! -f /etc/cron.allow ]]; then

#Create and make perms proper
 touch /etc/cron.allow
 chmod 700 /etc/cron.allow
 chown root:root /etc/cron.allow

#For everyone that has a crontab
	for f in "$(ls /var/spool/cron)"; do

#As long as they aren't root (because root can)
	 if [[ "$f" != "root" ]]; then echo "$f" >> /etc/cron.allow; fi
	done
fi
