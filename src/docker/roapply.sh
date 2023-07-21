#!/bin/bash
set -e

sleep 5

# Set up a login terminal on the serial console (ttyS0):
echo "Setting up tty"
ln -s agetty /etc/init.d/agetty.ttyS0
echo ttyS0 > /etc/securetty
rc-update add agetty.ttyS0 default

# Make sure special file systems are mounted on boot:
echo "Mounting on boot"
rc-update add devfs boot
rc-update add procfs boot
rc-update add sysfs boot

# mkdir -p /my-rootfs/home/user1

#seccomp has no support for ipv6 (rootless)
sleep 0.5
sed -i 's/#network_cmd_options = \[\]/network_cmd_options = \["enable_ipv6=false"\]/' /etc/containers/containers.conf

# READONLY ROOT
# echo "/dev/vda  /   tmpfs   ro,errors=remount-ro 0 1" >> /etc/fstab
sed -i '1i/dev/vda  /   tmpfs   ro,errors=remount-ro 0 1' /etc/fstab

# Then, copy the newly configured system to the rootfs image:
for d in bin etc lib root fc sbin usr home; do tar c "/$d" | tar x -C /my-rootfs; done

# The above command may trigger the following message:
# tar: Removing leading "/" from member names
# However, this is just a warning, so you should be able to
# proceed with the setup process.

# echo `ls -lh /dev/fuse` #not found, have to manually change grp and permissions in uVM
# echo `ls -lh /dev/net/tun` #not found, have to manually change grp and permissions in uVM

for dir in dev proc run sys ; do mkdir -p /my-rootfs/${dir}; done
mkdir -p /my-rootfs/tmp/containers-user-1001
mkdir -p /my-rootfs/var/tmp
chgrp -R user1 /my-rootfs/var
chmod -R 775 /my-rootfs/var
chown -R root:user1 /my-rootfs/fc
chmod -R 750 /my-rootfs/fc


echo "DONE applying"
