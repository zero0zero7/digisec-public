#!/bin/bash
set -e


# Download the base kernel config
cd assets
BASE_KERNEL_CONFIG="microvm-kernel-x86_64-5.10.config" 
wget -nc https://raw.githubusercontent.com/firecracker-microvm/firecracker/main/resources/guest_configs/$BASE_KERNEL_CONFIG

cd ~
# Clone the Firecracker repo which contains the devtool to build the Linux kernel
FIRECRACKER_REPO="https://github.com/firecracker-microvm/firecracker.git"
if [! -d $FIRECRACKER_REPO]
then
    git clone $FIRECRACKER_REPO
else
    echo "has Local Firecracker repo"
fi

# Copy base kernel config into FIrecracker local repo
cp $BASE_KERNEL_CONFIG ./firecracker/.config
echo "cd-ing into firecracker"
cd firecracker

# Set which modules to compile into the kernel
sed -i 's/^# CONFIG_IP6_NF_IPTABLES=.*/CONFIG_IP6_NF_IPTABLES=y/' .config
sed -i 's/^# CONFIG_NETFILTER_XT_MARK.*/CONFIG_NETFILTER_XT_MARK=y/' .config
sed -i 's/^# CONFIG_NETFILTER_XT_MATCH_COMMENT.*/CONFIG_NETFILTER_XT_MATCH_COMMENT=y/' .config
sed -i 's/^# CONFIG_NETFILTER_XT_MATCH_MULTIPORT.*/CONFIG_NETFILTER_XT_MATCH_MULTIPORT=y/' .config
sed -i 's/^# CONFIG_CRYPTO_CRC32_PCLMUL.*/CONFIG_CRYPTO_CRC32_PCLMUL=y/' .config
sed -i 's/^# CONFIG_CRYPTO_CRC32C_INTEL.*/CONFIG_CRYPTO_CRC32C_INTEL=y/' .config
sed -i 's/^# CONFIG_CRYPTO_GHASH_CLMUL_NI_INTEL.*/CONFIG_CRYPTO_GHASH_CLMUL_NI_INTEL=y/' .config
sed -i 's/^# CONFIG_CRYPTO_AES_NI_INTEL.*/CONFIG_CRYPTO_AES_NI_INTEL=y/' .config
sed -i 's/^# CONFIG_CRYPTO_CRYPTD.*/CONFIG_CRYPTO_CRYPTD=y/' .config
sed -i 's/^# CONFIG_INPUT_EVDEV.*/CONFIG_INPUT_EVDEV=y/' .config
sed -i 's/^# CONFIG_NET_SCH_FQ_CODEL.*/CONFIG_NET_SCH_FQ_CODEL=y/' .config
sed -i 's/^# CONFIG_AUTOFS4_FS.*/CONFIG_AUTOFS4_FS=y/' .config

# Build the Linux kernel pointing to the new config
./tools/devtool build_kernel -c ".config" -n 22

cp ~/firecracker/build/kernel/linux-5.10/vmlinux-5.10-x86_64.bin ~/Main/assets/vmlinux-5.10.bin