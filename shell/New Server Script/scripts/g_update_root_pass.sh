#!/bin/bash

#Check if running as root
if [ "$(id -u)" != "0" ]; then
	echo "This has to be run as root" 1>&2
	exit 1
fi

#For help
ip addr | grep "inet " | grep -v 127.0.0.1 | sed 's/\/.*$//'

#Update Root Password
echo "Please assign the new root password"
/usr/bin/passwd root