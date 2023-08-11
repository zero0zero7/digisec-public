#!/bin/bash
set -e


VM_ID="${1:-1}"
chroot_base="/jailer"
CHROOT_PATH="${chroot_base}/firecracker/${VM_ID}/root"
sudo mkdir -p "${CHROOT_PATH}"

API_SOCKET="${CHROOT_PATH}/run/firecracker.socket"
TAP_DEV="tap${VM_ID}"
# within private IP range "172.16.0.0 – 172.31.255.255"
TAP_IP="$(printf '172.16.%s.%s' $(((4 * VM_ID +1) / 256)) $(((4 * VM_ID +1) % 256)))"
VM_IP="$(printf '172.16.%s.%s' $(((4 * VM_ID +2) / 256)) $(((4 * VM_ID +2) % 256)))"
MASK_SHORT="/30"
uuid=$(uuidgen)
IFS='-' read -r throw u1 u2 u3 u <<< "$uuid"
u4=$(echo ${u:0:4})
u5=$(echo ${u:4:4})
u6=$(echo ${u:8:4})
TAP_IP6="fe80:$u1:$u2:$u3:$u4:$u5:$u6:0001"
VM_IP6="fe80:$u1:$u2:$u3:$u4:$u5:$u6:0002"
echo $TAP_IP6
echo $VM_IP6
MASK_SHORT6="/124"
VMv="${VM_IP6}"
VMv+="${MASK_SHORT6}"

# Setup network interface
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo ip link del "$TAP_DEV" 2> /dev/null || true
sudo ip tuntap add dev "$TAP_DEV" mode tap
sudo ip addr add "${TAP_IP}${MASK_SHORT}" dev "$TAP_DEV"
sudo ip -6 addr add "${TAP_IP6}${MASK_SHORT6}" dev "$TAP_DEV"
sudo ip link set dev "$TAP_DEV" up
sudo sh -c "echo 1 > /proc/sys/net/ipv6/conf/$TAP_DEV/forwarding"

FC_MAC="$(printf 'AA:FC:00:00:%02X:%02X' $((VM_ID / 256)) $((VM_ID % 256)))"

# Kernel
sudo cp -u "./build/vmlinux-5.10-x86_64.bin" "${chroot_base}/vmlinux-5.10-x86_64.bin"
KERNEL_FULL="${CHROOT_PATH}/vmlinux-5.10-x86_64.bin"
if sudo [ ! -e "${KERNEL_FULL}" ]; then
    sudo ln "${chroot_base}/vmlinux-5.10-x86_64.bin" "${KERNEL_FULL}"
fi 
sudo chmod 755 "${KERNEL_FULL}"
    
# Read-only rootfs
sudo cp -u "./build/rorootfs.ext4" "${chroot_base}/rorootfs.ext4"
ROOTFS_FULL="${CHROOT_PATH}/rorootfs.ext4"
if sudo [ ! -e "${ROOTFS_FULL}" ]; then
    sudo ln "${chroot_base}/rorootfs.ext4" "${ROOTFS_FULL}"
fi
sudo chmod 744 "${ROOTFS_FULL}"

# Read-write disk
if sudo [ ! -e "${CHROOT_PATH}/rw.ext4" ]; then
    sudo dd if=/dev/zero of=rw.ext4 bs=1M count=500
    sudo mkfs.ext4 rw.ext4
    sudo mv rw.ext4 "${CHROOT_PATH}/rw.ext4"
    # set up network in guest
    sudo mkdir -p /tmp/rw
    sudo mount "${CHROOT_PATH}/rw.ext4" /tmp/rw
    sudo cp ./src/firecracker/rw-setup.sh /tmp/rw
    sudo chmod 700 /tmp/rw/rw-setup.sh
    sudo sed -i "s|VM6|${VMv}|" /tmp/rw/rw-setup.sh
    sudo umount /tmp/rw
    # docker run -it --rm -v ./src/firecracker:/fc -v /tmp/rw:/my-rw alpine sh -c "ls fc && sed -i 's/VM_IP/$VM_IP/' /fc/rw-setup.sh && sed -i 's/TAP_IP/$TAP_IP/' /fc/rw-setup.sh && cat /fc/rw-setup.sh && cp -fr /fc /my-rw && ls /my-rw" && sudo umount /tmp/rw

fi
sudo chmod 666 -R "${CHROOT_PATH}/rw.ext4"

# Logfile
sudo touch "${CHROOT_PATH}/debug.log" 
sudo chmod 666 "${CHROOT_PATH}/debug.log" 

# Metrics
sudo touch "${CHROOT_PATH}/metrics.fifo" 
sudo chmod 666 "${CHROOT_PATH}/metrics.fifo" 

# Config file
if sudo [ ! -e "${CHROOT_PATH}/config.json" ]; then
    sudo cp src/config.json tmpconfig.json
    sudo chmod 666 "tmpconfig.json"
    sed -i "s/VM_IP/$VM_IP/" tmpconfig.json
    sed -i "s/TAP_IP/$TAP_IP/g" tmpconfig.json
    sed -i "s/TAP_DEV/$TAP_DEV/" tmpconfig.json
    sed -i "s/FC_MAC/$FC_MAC/" tmpconfig.json
    sudo mv tmpconfig.json "${CHROOT_PATH}/config.json"
fi
sudo chmod 666 "${CHROOT_PATH}/config.json"


export RUST_BACKTRACE=1
FC_DIR="${2:-/home/lxinyi6/firecracker-gitlab}"
uid=$(id -u)
gid=$(id -g)
ARCH="$(uname -m)"


FC="${FC_DIR}/build/cargo_target/${ARCH}-unknown-linux-musl/debug/firecracker"
JAIL="${FC_DIR}/build/cargo_target/${ARCH}-unknown-linux-musl/debug/jailer"

echo "before jail "
sudo "${JAIL}" --id "${VM_ID}" \
--exec-file "${FC}" --uid "${uid}" --gid "${gid}" \
--cgroup-version 2 \
--chroot-base-dir "${chroot_base}" \
-- \
--config-file "/config.json" 