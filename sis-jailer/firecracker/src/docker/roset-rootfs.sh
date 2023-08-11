#!/bin/bash
set -e

sh script/apk-install.sh

# Set root user and "root" as password
echo "root:root" | chpasswd
adduser -h /home/user1 -u 1001 -D user1 
echo "user1:user1" | chpasswd
touch /etc/subuid
touch /etc/subgid
echo "user1:165536:65536" > /etc/subuid
echo "user1:165536:65536" > /etc/subgid

sh script/roapply.sh


# Exit Docker container
exit