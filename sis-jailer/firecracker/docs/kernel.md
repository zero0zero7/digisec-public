# Steps to build Linux kernel for Firecracker microVM

1. Clone [Firecracker repo](https://github.com/firecracker-microvm/firecracker.git), edit the CPU string and build. Done via *sh src/firecracker-binary.sh*

2. Edit the base kernel config file to include nftables, fuse etc.

3. Build Linux kernel using the tool provided by Firecracker

4. The kernel image built will be placed in the *build/* folder