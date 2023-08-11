#!/bin/bash
set -e

# Set up a login terminal on the serial console (ttyS0):
ln -s agetty /etc/init.d/agetty.ttyS0
echo ttyS0 > /etc/securetty
rc-update add agetty.ttyS0 default

# Make sure special file systems are mounted on boot:
rc-update add devfs boot
rc-update add procfs boot
rc-update add sysfs boot

# Podman configuration files
# seccomp has no support for ipv6 (rootless)
sed -i 's/#network_cmd_options = \[\]/network_cmd_options = \["enable_ipv6=false"\]/' /etc/containers/containers.conf
# echo 'runroot = "/home/user1/run/containers/storage"' >> /etc/containers/storage.conf
# echo 'graphroot = "/home/user1/var/lib/containers/storage"' >> /etc/containers/storage.conf
echo 'static_dir = "/home/user1/var/lib/containers/storage/libpod"' >> /etc/containers/containers.conf
# echo 'tmp_dir = "/home/user1/run/libpod"' >> /etc/containers/containers.conf
echo 'volume_path = "/home/user1/var/lib/containers/storage/volumes"' >> /etc/containers/containers.conf
sed -i 's|\[engine\]|\[engine\] \nenv = \["TMPDIR=/home/user1/var/tmp"\]|' /etc/containers/containers.conf

# Auto-login as root upon boot
sed -i 's/#agetty_options=""/agetty_options="--autologin root --noclear"/' /etc/conf.d/agetty

# Auto-execute /fc/setup.sh on startup
cat <<EOF >/etc/local.d/setup.start
#!/bin/sh -e
/fc/setup.sh
EOF


chmod 750 /etc/local.d/setup.start

rc-update add local default

cp /script/cont /etc/init.d/cont
cp /script/launch-cont.sh /bin/launch-cont.sh
chmod 777 /bin/launch-cont.sh
chmod 777 /etc/init.d/cont
rc-update add cont default
rc-update del agetty.ttyS0 default

# Then, copy the newly configured system to the rootfs image:
for d in bin etc lib root fc sbin usr home; do tar c "/$d" | tar x -C /my-rootfs; done
for dir in dev proc run sys ; do mkdir -p /my-rootfs/${dir}; done

setcap cap_setuid+ep /my-rootfs/usr/bin/newuidmap 
setcap cap_setgid+ep /my-rootfs/usr/bin/newgidmap 

mkdir -p /my-rootfs/tmp/containers-user-1001
mkdir -p /my-rootfs/var/tmp
mkdir -p /my-rootfs/setup
chgrp -R user1 /my-rootfs/var
chmod -R 775 /my-rootfs/var
chown -R root:user1 /my-rootfs/fc
chmod -R 750 /my-rootfs/fc

cp /script/storage.conf /my-rootfs/etc/containers/storage.conf
chmod 755 /my-rootfs/etc/containers/storage.conf
