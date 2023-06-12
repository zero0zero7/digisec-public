#!/bin/bash
set -e


KERNEL="/home/lxinyi6/Main/assets/vmlinux-5.10.bin"
ROOTFS="/home/lxinyi6/Main/assets/rootfs.ext4"

TAP_DEV="tap0"
TAP_IP="172.16.0.1"
MASK_SHORT="/30"

# Setup network interface
# ignore for now since microVM cant get internet access anyway
sudo ip link del "$TAP_DEV" 2> /dev/null || true
sudo ip tuntap add dev "$TAP_DEV" mode tap
sudo ip addr add "${TAP_IP}${MASK_SHORT}" dev "$TAP_DEV"
sudo ip link set dev "$TAP_DEV" up

# Enable ip forwarding
# checked that it is already 1, by cat-ing the file
#sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

API_SOCKET="./firecracker.socket"
LOGFILE="./firecracker.log"
rm -f $LOGFILE

# Create log file
touch $LOGFILE

# Set log file
sudo curl -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"log_path\": \"${LOGFILE}\",
        \"level\": \"Debug\",
        \"show_level\": true,
        \"show_log_origin\": true
    }" \
    "http://localhost/logger"


KERNEL_BOOT_ARGS="console=ttyS0 reboot=k panic=1 pci=off ip=172.16.0.2:172.16.0.1:172.16.0.1:255.255.255.252::eth0:off"

ARCH=$(uname -m)

if [ ${ARCH} = "aarch64" ]; then
    KERNEL_BOOT_ARGS="keep_bootcon ${KERNEL_BOOT_ARGS}"
fi

# Set boot source
sudo curl --trace curl_logs/boot.log -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"kernel_image_path\": \"${KERNEL}\",
        \"boot_args\": \"${KERNEL_BOOT_ARGS}\"
    }" \
    "http://localhost/boot-source"


# Set rootfs
sudo curl --trace curl_logs/rootfs -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"drive_id\": \"rootfs\",
        \"path_on_host\": \"${ROOTFS}\",
        \"is_root_device\": true,
        \"is_read_only\": false
    }" \
    "http://localhost/drives/rootfs"

# The IP address of a guest is derived from its MAC address with
# `fcnet-setup.sh`, this has been pre-configured in the guest rootfs. It is
# important that `TAP_IP` and `FC_MAC` match this.
FC_MAC="06:00:AC:10:00:02"

# Set network interface
sudo curl --trace curl_logs/network -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"iface_id\": \"net1\",
        \"guest_mac\": \"$FC_MAC\",
        \"host_dev_name\": \"$TAP_DEV\"
    }" \
    "http://localhost/network-interfaces/net1"

# API requests are handled asynchronously, it is important the configuration is
# set, before `InstanceStart`.
sleep 0.015s

echo "starting microVM"
sleep 0.1s

# Start microVM
sudo curl --trace curl_logs/start.log -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"action_type\": \"InstanceStart\"
    }" \
    "http://localhost/actions"


# API requests are handled asynchronously, it is important the microVM has been
# started before we attempt to SSH into it.
sleep 0.015s

# SSH into the microVM
#sudo ssh -i ./ubuntu-18.04.id_rsa 172.16.0.2
ssh root@172.16.0.2

# Use `root` for both the login and password.
# Run `reboot` to exit.
