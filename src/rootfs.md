# Steps to make a root file system 

```
./succ/streamline/mount-rootfs.sh
```

1. Create and Mount rootfs
    1. Create empty ext4 file system image of desirable size
    2. Mount rootfs onto local directory
    3. Copy Podman images into local dir

2. Mount rootfs onto Docker Alpine Linux container to load packages
    entrypoint is set to run ./set-rootfs.sh
    1. Use apk to install packages
    2. Configure network interface
    3. Set root password
    4. Copy root directory of container onto the rootfs
    5. Ensure that podman and nftables work


<br>

*mount-rootfs --> set-rootfs --> apk-install & apply*