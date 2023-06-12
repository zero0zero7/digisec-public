#!/bin/bash
set -e


apk update && apk upgrade

# Install packages
if apk add openrc ; then
        echo "OK openrc"
else
        echo "FAILED openrc"
fi
if apk add util-linux ; then
        echo "OK util-linux"
else
        echo "FAILED util-linux"
fi
if apk add podman ; then
        echo "OK podman"
else
        echo "FAILED podman"
fi
if apk add nftables ; then
        echo "OK nftables"
else
        echo "FAILED nftables"
fi
apk add net-tools
apk add kmod


rm -f /etc/network/interfaces

# Configure network interface 
ETH=`ifconfig -a | sed 's/[ \t].*//;/^$/d' | grep e`
INTERFACE_FILE="/etc/network/interfaces"
cd /
mkdir -p /etc/network
touch ${INTERFACE_FILE}
echo "auto ${ETH}" >> ${INTERFACE_FILE}
echo "iface eth0 inet static" >> ${INTERFACE_FILE}
echo "  address 172.16.0.2" >> ${INTERFACE_FILE}
echo "  netmask 255.255.255.252" >> ${INTERFACE_FILE}
echo "  gateway 172.16.0.1" >> ${INTERFACE_FILE}


echo "NOW, PASSWD for ROOT USER"