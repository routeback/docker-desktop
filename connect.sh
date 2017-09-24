#!/bin/bash
#
# Name: connect.sh
# Auth: Frank Cass
# Date: 20170920
# Desc: Quick setup script for docker-desktop
# 	Starts the docker container
#	SSH's into it
#	Uses xpra for a remote desktop session
#
###

which sshpass &>/dev/null
	if [[ $? -ne 0 ]]; then
	    echo "[!] sshpass needs to be installed to run this script. Try: sudo apt install sshpass"
	    exit 1
	fi

which xpra &>/dev/null
	if [[ $? -ne 0 ]]; then
	    echo "[!] xpra needs to be installed to run this script. Try: sudo apt install xpra"
	    exit 1
	fi


echo "[*] Starting up docker-desktop..."
	CONTAINER_ID=$(docker run -d -P routeback/docker-desktop)
	password=$(echo $(docker logs $CONTAINER_ID | sed -n 1p) | cut -d ":" -f 3 | cut -d " " -f 2)
	port=$(docker port $CONTAINER_ID 22 | cut -d ":" -f 2)
	ip=$(ifconfig | grep "inet addr:" | grep -v 127.0.0.1 | sed 's/inet addr://g' | cut -d ":" -f 1 | awk '{$1=$1}{ print }' | cut -d " " -f 1 | uniq | grep -v 172) # The grep -v 172 should be removed for users with Class B IPs

echo "[*] Sleeping so that docker container can startup... [3s]"; sleep 3
	sshpass -p $password ssh -q -oStrictHostKeyChecking=no docker@$ip -p $port "sh -c './docker-desktop -s 1600x900 -d 10 > /dev/null 2>&1 &'"


# Specify an application to be run on startup
###### read -p "[*] Enter the name of an application to run: " app
#######sshpass -p $password ssh -q -oStrictHostKeyChecking=no docker@$ip -p $port "sh -c DISPLAY=:10 $app > /dev/null 2>&1 &"

echo "[*] Sleeping so that the xpra server can startup... [10s]"; sleep 10

echo "[*] Connecting to docker-desktop with xpra"
	# sudo -u nobody $0 # Drop from root when running xpra
	sshpass -p $password xpra --ssh="ssh -q -oStrictHostKeyChecking=no -p $port" attach ssh:docker@$ip:10 > /dev/null 2>&1 &

	if [ $? -eq 0 ]; then
		echo "[*] Remote connection established!"
		echo "[*] Login with password: docker:$password"
	else
		echo "[*] Something went wrong... Unable to connect."
	fi

# xpra does not cleanly exit, running processes persist and potentially cause issues with accessing the remote host when run a second time
read -p "[*] Press enter to kill xpra when you are done." return; pgrep xpra | xargs kill
	if [ $? -eq 0 ]; then
	        echo "[*] Exiting."
	else
	        echo "[*] Something went wrong... Check for remaining running xpra processes."
	fi

