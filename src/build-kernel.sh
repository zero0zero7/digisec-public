#!/bin/bash
set -e

FC_DIR=${1:-$HOME/firecracker-original}
cd "${FC_DIR}"

# Download the base kernel config
rm -f kernel.config
cp resources/guest_configs/microvm-kernel-x86_64-5.10.config kernel.config


# Set which modules to compile into the kernel
echo "CONFIG_NETFILTER_XT_MARK=y" >> kernel.config
echo "CONFIG_NETFILTER_XT_MATCH_COMMENT=y" >> kernel.config
echo "CONFIG_NETFILTER_XT_MATCH_MULTIPORT=y" >> kernel.config
echo "CONFIG_CRYPTO_CRC32_PCLMUL=y" >> kernel.config
echo "CONFIG_CRYPTO_CRC32C_INTEL=y" >> kernel.config
echo "CONFIG_NET_SCH_FQ_CODEL=y" >> kernel.config
# For fuse-overlay as non-root in uMV
echo "CONFIG_AUTOFS4_FS=y" >> kernel.config
echo "CONFIG_FUSE_FS=y" >> kernel.config
# For entropy
echo "CONFIG_VIRTIO=y" >> kernel.config
echo "CONFIG_HW_RANDOM=y" >> kernel.config
echo "CONFIG_HW_RANDOM_VIRTIO=y" >> kernel.config



# Build the Linux kernel pointing to the new config
./tools/devtool build_kernel -c "kernel.config" -n 22

sudo cp build/kernel/linux-5.10/vmlinux-5.10-x86_64.bin /jailer/vmlinux-5.10-x86_64.bin