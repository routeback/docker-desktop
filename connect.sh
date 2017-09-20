#!/bin/bash

which sshpass &>/dev/null
if [[ $? -ne 0 ]]; then
    echo "[!] sshpass needs to be installed to run this script. Try: sudo apt install sshpass"
    exit 1
fi

echo "[*] Starting up docker-desktop..."
CONTAINER_ID=$(docker run -d -P routeback/docker-desktop)
echo $(docker logs $CONTAINER_ID | sed -n 1p)
password=$(echo $(docker logs $CONTAINER_ID | sed -n 1p) | cut -d ":" -f 3 | cut -d " " -f 2)
port=$(docker port $CONTAINER_ID 22 | cut -d ":" -f 2)
ip=$(ifconfig | grep "inet addr:" | grep -v 127.0.0.1 | sed 's/inet addr://g' | cut -d ":" -f 1 | awk '{$1=$1}{ print }' | cut -d " " -f 1 | uniq | grep -v 172) # The grep -v 172 should be removed for users with Class B IPs
echo "[*] Sleeping so that docker container can startup... [3s]"; sleep 3
sshpass -p $password ssh -q -oStrictHostKeyChecking=no docker@$ip -p $port "sh -c './docker-desktop -s 1920x1045 -d 10 > /dev/null 2>&1 &'"
echo "[*] Sleeping so that the xpra server can startup... [10s]"; sleep 10
# sudo -u nobody $0 # Drop from root when running xpra
sshpass -p $password xpra --ssh="ssh -q -oStrictHostKeyChecking=no -p $port" attach ssh:docker@$ip:10
