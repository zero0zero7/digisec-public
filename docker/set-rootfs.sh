#!/bin/bash
set -e


sh script/apk-install.sh

sleep 0.5

echo "Changing password"
# Set root user and "root" as password
echo "root:root" | chpasswd

sleep 0.5

mkdir -p /var/tmp
rc-update add cgroups
rc-service cgroups start

sleep 0.5

sh script/apply.sh

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

sleep 0.5

# Exit Docker container
exit