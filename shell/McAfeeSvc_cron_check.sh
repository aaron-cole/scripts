#!/bin/sh

#Services
#Should be all installed McAfee software

#NOTE - Policy Auditor is not a registered service
# that check is included in each section

rhelsvc=( "cma" "nails" "accm" )
sunossvc=( "cma" "accm" "auditengine" "hips" )
#HPUX only has cma and policy auditor
pa="/opt/McAfee/auditengine/bin/auditmanager"


#Log File to log to
rhellog="/var/log/messages"
hpuxlog="/var/adm/syslog/syslog.log"
sunlog="wherever"

########################################
#Do not change below this point#
#########################################

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
echo "to be added" >> /dev/null



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
