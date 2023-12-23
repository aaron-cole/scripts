#!/bin/sh

#Check if running as root
if [ "$(id -u)" != "0" ]; then
	echo "This has to be run as root" 1>&2
	exit 1
fi

#Check for First argument
#Translating PORT to HEX Value
case $1 in
	10022) PORTHEXCLEAR="2726" ;;
	20022) PORTHEXCLEAR="4e36" ;;
	30022) PORTHEXCLEAR="7546" ;;
	40022) PORTHEXCLEAR="9c56" ;;
	50022) PORTHEXCLEAR="c366" ;;
	60022) PORTHEXCLEAR="ea76" ;;
	2726|4e36|7546|9c56|c366|ea76) PORTHEXCLEAR="$1"
	*) echo "You must specify an approved port in decimal or hex"
		 echo "Please Re-run with an approved port"
		 exit 1;;
esac

PASS=0

#We should never have more than 1 SOCKET
#If we do then it was entered wrong
while [ $PASS -eq 0 ]; do

#Since we have the hex value of the port we can
#query for the connections
	echo ""
	echo "This is the list of connections for that port"
	ndd -get /dev/tcp tcp_status | grep "\[$PORTHEXCLEAR,"

#Now we have to have the person give the socket 
#for the connection from above
	echo ""
	echo "Copy and Paste or type the socket from above to disconnect"
	read -r SOCKETINPUT

#Lets check it
	if [ "$(ndd -get /dev/tcp tcp_status | grep "\[$PORTHEXCLEAR," | grep "^$SOCKETINPUT" | wc -l)" -eq 1 ]; then
		if [ "$(ndd -get /dev/tcp tcp_status | grep "\[$PORTHEXCLEAR," | grep "^$SOCKETINPUT" | awk '{print $1}')" = "$SOCKETINPUT" ]; then
			PASS=1
		else
			echo "Doesn't seem to be right - try again..."
		fi
	else
		echo "Doesn't seem to be right - try again..."
	fi
done

#If we are good to go, lets clear it

echo ""
echo "WARNING: IS THIS THE CONNECTION TO CLEAR?"
ndd -get /dev/tcp tcp_status | grep "\[$PORTHEXCLEAR," | grep "^$SOCKETINPUT"
echo "[Y]es/[N]o?"
read -r ANSWER
case "$ANSWER" in
	y|Y|[yY][eE][sS]) echo "Clearing connection"
										SOCKETCLEAR="0x$SOCKETINPUT"
										ndd -set /dev/tcp tcp_discon "$SOCKETCLEAR"
										if [ $? -eq 0 ]; then
											echo "PORT SUCCESSFULLY CLEARED!"
										else
											echo "PORT NOT CLEARED SUCCESSFULLY"
										fi
										;;
	 	
	*) echo "Canceled. No Changes have been made.";;
esac
	