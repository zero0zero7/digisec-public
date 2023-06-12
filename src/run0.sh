#!/bin/bash
set -e


ARCH="$(uname -m)"

API_SOCKET="./firecracker.socket"

# Remove API unix socket
rm -f $API_SOCKET

# Run firecracker
~/firecracker/build/cargo_target/${ARCH}-unknown-linux-musl/debug/firecracker \
    --api-sock "${API_SOCKET}"
