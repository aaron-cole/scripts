#!/bin/sh

if [ -f /var/spool/ldapcltd/status ]; then
 rm /var/spool/ldapcltd/status
fi

if [ -f /var/spool/ldapcltd/daemon ]; then
 rm /var/spool/ldapcltd/daemon
fi
