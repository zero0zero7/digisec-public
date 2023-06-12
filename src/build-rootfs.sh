#!/bin/bash
set -e


SIZE=$1

# Create empty ext4 file system image
dd if=/dev/zero of=rootfs.ext4 bs=1M count=$SIZE
mkfs.ext4 rootfs.ext4

mkdir -p /tmp/another-rootfs
if mountpoint -q /tmp/another-rootfs; then
    echo "/tmp/another-rootfs already mounted"
    sudo umount /tmp/another-rootfs
else
    echo "NOT mounted"
fi
sudo mount rootfs.ext4 /tmp/another-rootfs

# Copy previously saved Podman images into rootfs
sudo cp ~/podtar/alp.tar ~/podtar/ngx.tar ~/podtar/rocky8.tar /tmp/another-rootfs

docker run -it --rm -v /tmp/another-rootfs:/my-rootfs -v /home/lxinyi6/Main/docker:/script alpine sh -c "sh script/set-rootfs.sh"

# Unmount rootfs from local dir
sudo umount /tmp/another-rootfs

mv rootfs.ext4 ~/Main/assets