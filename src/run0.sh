#!/bin/bash
set -e

VM_ID="${1:-1}"
FC_DIR="${2:-$HOME/firecracker}"

ARCH="$(uname -m)"
CUR_DIR="$(pwd)"

API_SOCKET="${CUR_DIR}/firecracker${VM_ID}.socket"

# Remove API unix socket
rm -f $API_SOCKET

# Run firecracker
${FC_DIR}/build/cargo_target/${ARCH}-unknown-linux-musl/debug/firecracker \
    --api-sock "${API_SOCKET}"
# ~/firecracker-worked/build/cargo_target/${ARCH}-unknown-linux-musl/debug/firecracker \
#     --api-sock "${API_SOCKET}"
