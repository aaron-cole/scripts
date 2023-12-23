#!/bin/sh
########################################
#Name		McAfeeSvc_cron_check.sh
#Created by	Aaron Cole
#Version 	1.0
#Date		9/10/2015
#Synopsis:	
# This script will check the running
# status of all required McAfee services
# that should be installed on each system,
# and start them. If it starts them, then
# it will log to the log file.
#
# A cron job calling on this script, is
# the overall purpose.  However the
# script can be run as is.
#
# This script should be POSIX compliant,
# and run on Red Hat, HP-UX, and Solaris
# - all versions.
########################################

#Services
#Should be all installed McAfee software

#NOTE - Policy Auditor is not a registered service
# that check is included in each section

rhelsvc=( "cma" "nails" "accm" )
sunossvc=( "cma" "accm" )
#HPUX only has cma and policy auditor
pa="/opt/McAfee/auditengine/bin/auditmanager"


#Log File to log to
rhellog="/var/log/messages"
hpuxlog="/var/adm/syslog/syslog.log"
sunlog="/var/adm/messages"

########################################
#Do not change below this point#
#########################################

#Check if running as root
if [ "$(id -u)" != "0" ]; then
        echo "This has to be run as root" 1>&2
        exit 1
fi

#Platform determination
platform=`uname`

###RHEL###
if [ "$platform" = "Linux" ] ; then
	for service in ${rhelsvc[@]}; do
		if (( $(ps -ef | grep -v grep | grep $service | wc -l) < 1 )) ; then
					
		#Restart service and echo to syslog
			/etc/init.d/$service restart 
			echo "$(date +%b\ %d\ %T) $(hostname) McAfeeSvc_cron_check.sh Restarting $service because it was stopped" >> $rhellog		 
		
		#maybe put secondary check in???
		fi
	done
	
	if (( $(ps -ef | grep -v grep | grep $pa | wc -l) < 1 )) ; then
		"$pa" restart
		echo "$(date +%b\ %d\ %T) $(hostname) McAfeeSvc_cron_check.sh Restarting PolicyAuditor because it was stopped" >> $rhellog
	fi

###Solaris###
elif [ "$platform" =  "SunOS" ]  ; then
#checks fo SunOS
	for service in ${sunossvc[@]}; do
                if (( $(ps -ef | grep -v grep | grep $service | wc -l) < 1 )) ; then

                 #Restart service and echo to syslog
                 /etc/init.d/$service restart
                 echo "$(date +%b\ %d\ %T) $(hostname) McAfeeSvc_cron_check.sh Restarting $service because it was stopped" >> $sunlog
                fi
	done

        if (( $(ps -ef | grep -v grep | grep $pa | wc -l) < 1 )) ; then

        #Restart service and echo to syslog
        "$pa" restart
        echo "$(date +%b\ %d\ %T) $(hostname) McAfeeSvc_cron_check.sh Restarting PolicyAuditor because it was stopped" >> $sunlog
        fi

	if [[ "$(uname -r)" != "5.11" ]] ; then
		if (( $(ps -ef | grep -v grep | grep "HipClient" | wc -l) < 1 )) ; then

       		 #Restart service and echo to syslog
        	 /opt/McAfee/hip/HipClient-bin -d
        	 echo "$(date +%b\ %d\ %T) $(hostname) McAfeeSvc_cron_check.sh Restarting HipClient because it was stopped" >> $sunlog
        	fi

	fi

###HP-UX###
elif [ "$platform" = "HP-UX" ] ; then
#Agent
	if (( $(ps -ef | grep -v grep | grep cma | wc -l) < 1 )) ; then
	
 	 #Restart service and echo to syslog
	 /sbin/init.d/$service restart 
	 echo "$(date +%b\ %d\ %T) $(hostname) McAfeeSvc_cron_check.sh Restarting cma because it was stopped" >> $hpuxlog
	fi

	if (( $(ps -ef | grep -v grep | grep $pa | wc -l) < 1 )) ; then
	
	 #Restart service and echo to syslog
         "$pa" restart
         echo "$(date +%b\ %d\ %T) $(hostname) McAfeeSvc_cron_check.sh Restarting PolicyAuditor because it was stopped" >> $hpuxlog
	fi


fi
