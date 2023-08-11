#!/bin/bash
set -e
set -x

CUR_DIR="$(pwd)"
SIZE=${1:-3000}
MOUNTPT=$(mktemp -d)

function cleanup {
  echo "Unmounting "
  rm rorootfs.ext4
  sudo umount $MOUNTPT
}

trap cleanup EXIT

# Create empty ext4 file system image
dd if=/dev/zero of=rorootfs.ext4 bs=1M count=$SIZE
mkfs.ext4 rorootfs.ext4

sudo mount rorootfs.ext4 $MOUNTPT
docker run -it --rm -v ${CUR_DIR}/src/firecracker:/fc -v $MOUNTPT:/my-rootfs -v ${CUR_DIR}/src/docker:/script alpine sh -c "sh script/roset-rootfs.sh"

sudo mkdir -m 755 -p $MOUNTPT/var/lib/ctr
sudo chmod 755 $MOUNTPT/var/lib
sudo chmod 755 $MOUNTPT/var

sudo mkdir -m 755 -p $MOUNTPT/etc/containers
sudo touch $MOUNTPT/etc/containers/storage.conf

# cat -n $MOUNTPT/etc/containers/storage.conf

sudo curl -o ./build/sisclient.tar http://mirror.rt.dts.dso/sis/sisclient.tar 
sudo chmod 644 ./build/sisclient.tar
docker run --privileged -it --rm -v ./build/sisclient.tar:/tmp/sisclient.tar -v $MOUNTPT:/my-rootfs quay.io/podman/stable sh -c "podman --root=/my-rootfs/var/lib/ctr load < /tmp/sisclient.tar" 

sudo chmod 777 $MOUNTPT/etc/init.d/cont
sudo umount $MOUNTPT

mkdir -p -m 755 ./build
sudo mv rorootfs.ext4 ./build/rorootfs.ext4