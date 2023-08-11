#!/bin/bash
set -e

VM_ID="${1:-1}"
FC_DIR="${2:-$HOME/firecracker}"
ARCH="$(uname -m)"
CUR_DIR="$(pwd)"

mkdir -p ./sockets
API_SOCKET="${CUR_DIR}/sockets/firecracker${VM_ID}.socket"

# Create a rw.ext4 in /
if sudo [ ! -e /rw.ext4 ]; then
    sudo dd if=/dev/zero of=rw.ext4 bs=1M count=500
    sudo mkfs.ext4 rw.ext4
    sudo mv rw.ext4 /rw.ext4
    sudo chmod 666 /rw.ext4
fi

# Remove API unix socket
rm -f $API_SOCKET

# Run firecracker
${FC_DIR}/build/cargo_target/${ARCH}-unknown-linux-musl/debug/firecracker \
    --api-sock "${API_SOCKET}"