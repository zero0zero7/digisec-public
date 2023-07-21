#!/bin/bash
set -e

CUR_DIR="$(pwd)"

SIZE=${1:-2400}


function cleanup {
  echo "Unmounting "
  rm rorootfs.ext4
  sudo umount /tmp/another-rootfs
}


trap cleanup EXIT

# Create empty ext4 file system image
dd if=/dev/zero of=rorootfs.ext4 bs=1M count=$SIZE
mkfs.ext4 rorootfs.ext4

mkdir -p /tmp/another-rootfs
if mountpoint -q /tmp/another-rootfs; then
    echo "/tmp/another-rootfs already mounted"
    sudo umount /tmp/another-rootfs
else
    echo "NOT mounted"
fi
sudo mount rorootfs.ext4 /tmp/another-rootfs
echo "MOUNTED"

# Copy previously saved Podman images into rootfs
#sudo cp ${CUR_DIR}/assets/podtar/alp.tar /tmp/another-rootfs

docker run -it --rm -v ${CUR_DIR}/src/firecracker:/fc -v /tmp/another-rootfs:/my-rootfs -v ${CUR_DIR}/src/docker:/script alpine sh -c "ls && ls script && sh script/roset-rootfs.sh" && sudo umount /tmp/another-rootfs

# Unmount rootfs from local dir
# sudo umount /tmp/another-rootfs


mkdir -p ${CUR_DIR}/assets
mv rorootfs.ext4 ${CUR_DIR}/assets/rorootfs3.ext4
sudo cp ${CUR_DIR}/assets/rorootfs3.ext4 /jailer/rorootfs.ext4