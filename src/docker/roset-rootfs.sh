#!/bin/bash
set -e


sh script/apk-install.sh

sleep 0.5

echo "Changing password"
# Set root user and "root" as password
echo "root:root" | chpasswd

sleep 0.5

# rc-update add cgroups
# rc-service cgroups start

echo "Adding user"
adduser -h /home/user1 -u 1001 -D user1 
echo "user1:user1" | chpasswd
if [ -e /etc/subuid ]
then
    echo "user1:165536:65536" > /etc/subuid
    echo "user1:165536:65536" > /etc/subgid
else
    touch /etc/subuid
    touch /etc/subgid
    echo "user1:165536:65536" > /etc/subuid
    echo "user1:165536:65536" > /etc/subgid
fi

echo "Entering apply.sh"
sh script/roapply.sh

sleep 0.5


echo "trying PODMAN"
# Ensure podman works
if podman --version | grep -q "podman version";
then    
    echo "podman OK"
fi
echo "trying NFT"
# Ensure nftables works
if nft --version | grep -q "nftables v" ; then    
    echo "nftables OK"
else 
    echo "NFTABLES FAILED"
fi

# Exit Docker container
exit