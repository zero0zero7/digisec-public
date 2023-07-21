#!/bin/sh
set -e

export RUST_BACKTRACE=1

VM_ID="${1:-1}"
FC_DIR="${2:-/home/lxinyi6/firecracker-gitlab}"
uid="${3:-1001}"
gid="${4:-1001}"

ARCH="$(uname -m)"

# Ensure that chroot_base is not in a filesystem that is mounted with nodev 
# Using `mount | grep -v "nodev"`s
chroot_base="/jailer"
mkdir -p "${chroot_base}"

FC="${FC_DIR}/build/cargo_target/${ARCH}-unknown-linux-musl/debug/firecracker"
JAIL="${FC_DIR}/build/cargo_target/${ARCH}-unknown-linux-musl/debug/jailer"

API_SOCKET="/home/lxinyi6/${chroot_base}/firecracker/${VM_ID}/root/run/firecracker.socket"


${JAIL} --id ${VM_ID} \
--exec-file ${FC} --uid "${uid}" --gid "${gid}" \
--cgroup-version 2 \
--chroot-base-dir "${chroot_base}"

