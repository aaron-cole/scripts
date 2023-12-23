#!/bin/sh

#Update Configurations to make the Server operational

#ntp
sed -i 's/76/74/g' /etc/ntp.conf
service ntpd restart

#SNMPD
sed -i 's/clone/home/g' /etc/snmp/snmpd.conf
service snmpd restart

#DNS
sed -i 's/127.0.0.1/8.8.8.8/g' /etc/resolv.conf

#logger
sed -i 's/19/91/g' /etc/rsyslog.conf
service rsyslog restart

#TimeZone
echo 'ZONE="America/Los_Angeles"' > /etc/sysconfig/clock
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
