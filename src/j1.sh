#!/bin/bash
set -e

VM_ID="${1:-1}"
# chroot_base="/srv/jailer"
chroot_base="/jailer"


KERNEL_FULL="${chroot_base}/firecracker/${VM_ID}/root/vmlinux-5.10-x86_64.bin"
if sudo [ ! -e "${KERNEL}" ]; then
    # use copy because unable to hard-link across devices / and /dev (on different partitions)
    # sudo cp /home/lxinyi6/firecracker-original/build/kernel/linux-5.10/vmlinux-5.10-x86_64.bin "${KERNEL_FULL}"
    sudo ln ${chroot_base}/vmlinux-5.10-x86_64.bin "${KERNEL_FULL}"
    sudo chmod 777 "${KERNEL_FULL}"
else 
    echo "KERNEL LINK EXISTS"
    sudo ls -la "${KERNEL_FULL}"
fi


ROOTFS_FULL="${chroot_base}/firecracker/${VM_ID}/root/rootfs.ext4"
if sudo [ ! -e "${ROOTFS}" ]; then
    # use copy because unable to hard-link across devices / and /dev (on different partitions)
    # sudo cp /home/lxinyi6/sis/firecracker/assets/rootfs3.ext4 "${ROOTFS_FULL}"
    sudo ln ${chroot_base}/rootfs.ext4 "${ROOTFS_FULL}"
    sudo chmod 666 "${ROOTFS_FULL}"
else 
    echo "ROOTFS LINK EXISTS"
    sudo ls -la "${ROOTFS_FULL}"
fi


API_SOCKET="${chroot_base}/firecracker/${VM_ID}/root/run/firecracker.socket"
TAP_DEV="tap${VM_ID}"
# within private IP range "172.16.0.0 – 172.31.255.255"
TAP_IP="$(printf '172.16.%s.%s' $(((4 * VM_ID +1) / 256)) $(((4 * VM_ID +1) % 256)))"
VM_IP="$(printf '172.16.%s.%s' $(((4 * VM_ID +2) / 256)) $(((4 * VM_ID +2) % 256)))"
MASK_SHORT="/30"

printf "Setting up IP dev\n"
# Setup network interface
sudo ip link del "$TAP_DEV" 2> /dev/null || true
sudo ip tuntap add dev "$TAP_DEV" mode tap
sudo ip addr add "${TAP_IP}${MASK_SHORT}" dev "$TAP_DEV"
sudo ip link set dev "$TAP_DEV" up
printf "Done with IP dev\n\n"

# Enable ip forwarding
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

# KERNEL_BOOT_ARGS="console=ttyS0 reboot=k panic=1"
KERNEL_BOOT_ARGS="console=ttyS0 reboot=k panic=1 cgroup_no_v1="all" cgroup.memory=nokmem pci=off ip=${VM_IP}:${TAP_IP}:${TAP_IP}:255.255.255.252::eth0:off"

ARCH=$(uname -m)

if [ ${ARCH} = "aarch64" ]; then
    KERNEL_BOOT_ARGS="keep_bootcon ${KERNEL_BOOT_ARGS}"
fi

# KERNEL="/hello-vmlinux.bin"
KERNEL="/vmlinux-5.10-x86_64.bin"
# Set boot source
# sudo is required since API_OSKCET belongs to root user
# the kernel_image_path should be relative to /chroot_base/vm_id/root 
sudo curl -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"kernel_image_path\": \"${KERNEL}\",
        \"boot_args\": \"${KERNEL_BOOT_ARGS}\"
    }" \
    "http://localhost/boot-source"
printf "\ncurled KERNEL\n"

# Set rootfs
# the path_on_host should be relative to /chroot_base/vm_id/root 
ROOTFS="/rootfs.ext4"
sudo curl -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"drive_id\": \"rootfs\",
        \"path_on_host\": \"${ROOTFS}\",
        \"is_root_device\": true,
        \"is_read_only\": false
    }" \
    "http://localhost/drives/rootfs"
printf "\n curled ROOTFS\n"

# Set network interface
FC_MAC="$(printf '02:FC:00:00:%02X:%02X' $((VM_ID / 256)) $((VM_ID % 256)))"
sudo curl -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"iface_id\": \"net1\",
        \"guest_mac\": \"$FC_MAC\",
        \"host_dev_name\": \"$TAP_DEV\"
    }" \
    "http://localhost/network-interfaces/net1"
printf "\n curled NETWORK\n"
# API requests are handled asynchronously, it is important the configuration is set, before `InstanceStart`.
# sleep 0.015s


# Start microVM
printf "\n Starting microVM\n"
sudo curl -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"action_type\": \"InstanceStart\"
    }" \
    "http://localhost/actions"


# Use `root` for both the login and password.
# Run `reboot` to exit.
