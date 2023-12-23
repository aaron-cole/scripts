#!/bin/bash

############################################
#Proper execution of this script will be as follows
#First agrument will either be system or path_to_file
#./script system 	- will tar defs of current system
#		  	- and transfer to pre-defined system
#./script path_to_file_name  	- Will use the tarball of provided file
#				- and transfer to pre-defined systems
#Second option is optional
#./script system path_to_file_name 	- use system defs and transfer
#					- to provided system list
#./script path_to_file_name path_to_file_name -use provided tarball and 
#					      - transfer to provide systems	
############################################

#Check if running as root
#if [ "$(id -u)" != "0" ]; then
#        echo "This has to be run as root" 1>&2
#        exit 1
#fi

#Variables
SystemList="/tmp/System_List"
ReportFile="/tmp/Report"

#Check first arg
if [ -n "$1" ] ;then
  if [[ "$1" == "system" ]]; then
   DATdate="$(date +%F)"
   DATname="dat_$DATdate.tar"
   DATFILE="/tmp/$DATname"
   sudo tar cvf "$DATFILE" -C /opt/NAI/LinuxShield/engine/dat/ .
  else
    if [ -f "$1" ]; then
      if [ ${1: -4} == ".tar" ]; then
       cp "$1" /tmp/
       DATFILE="/tmp/$(basename $1)"    
      else
       echo "File is not a regular tarball"
       exit 1
      fi
    else
     echo "The DAT file is doesn't exist or full path wasn't given"
     exit 1
    fi 
   exit 1
  fi
else
 echo "Please provide the word system or the DAT tarball file with full path"
 exit 1
fi 

sudo chmod 744 "$DATFILE"

#Check Second arg
if [ -n "$2" ]; then
  if [ -f "$2" ] ; then
    SystemList="$2"
  else
    echo "Provided System List is not a file or doesn't exist"
    exit 2
  fi
else
  if [ ! -f "$SystemList" ]; then
    echo "Predefined System List does not exist"
  fi
fi

#Start Loop for each server
for f in $(cat "$SystemList"); do

#Copy new DAT file over  
scp -q -o LogLevel=Error "$DATFILE" $f:/tmp

#Want to log all copies
#and only SSH to the successful copies
  if [[ $? -ne 0 ]]; then
    echo "$DATdate $f scp failed" >> "$ReportFile"
  else
    echo "$DATdate $f scp success" >> "$ReportFile"

#SSH TO SERVER
    ssh -t $f "tar xvf $DATFILE; sudo mv -f ./*.dat /usr/local/uvscan; sudo chown -R root:root /usr/local/uvscan; rm -rf $DATFILE"
    if [[ $? -ne 0 ]]; then
      echo "$DATdate $f ssh failed" >> "$ReportFile"
    else
      echo "$DATdate $f ssh success" >> "$ReportFile"
    fi
  fi
done

#Cleanup
