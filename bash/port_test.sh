#!/bin/bash

if [ -z "$1" ]; then 
 echo "You must provide a valid host name"
fi

if [ -z "$2" ]; then
 echo "You must provide a valid port"
fi

if [ -z "$3" ]; then
 COUNTER=0
else
 COUNTER=$3
fi

if [ $COUNTER -eq 0 ] ;then 
#Will Never exit and keep looping
 while [ $COUNTER -lt 10 ]; do
  echo > /dev/tcp/$1/$2 && echo "it's up" || echo "it's down"
  sleep 5
 done
else
#Perform the amount of times given
 i=0
 while [ $COUNTER -ne $i ]; do
  echo > /dev/tcp/$1/$2 && echo "it's up" || echo "it's down"
  sleep 5
  let i=i+1
 done
fi


