# Production Setup

## Jailer
1. Execute src/jailer.sh in terminal A with root permissions. <br>
`sudo ./src/jailer.sh VM_ID` <br>
This script corresponds to src/run0.sh in a non-jailer setup. <br>
In this script, we set up a chroot jail for the indicated user at the <chroot_base> directory, and fire a microVM instance within that jail. This would result in a directory structure as below:
    ```
    <chroot_base>
        ├── <vm_id>
        │   └── root
        │       ├── dev
        │       │   ├── kvm
        │       │   ├── net
        │       │   │   └── tun
        │       │   └── urandom
        │       ├── firecracker
        │       └── run
        │           └── firecracker.socket
    ```
    * Note that <chroot_base> should be in a filesystem that is NOT mounted with *nodev*

2. Execute src/j1.sh in terminal B <br>
`./src/jailer.sh VM_ID` <br>
This script corresponds to src/run1.sh in a non-jailer setup. <br>
In this script, we make a copy of the linux kernel image and a copy of the rootfs in our chroot jail. If the <chroot_base> is in the same partition as the kernel image and rootfs, it would be sufficient to just make a hard-link for each. Regardless, this would result in a directory structure as below:
    ```
    <chroot_base>
        ├── <vm_id>
        │   └── root
        │       ├── dev
        │       │   ├── kvm
        │       │   ├── net
        │       │   │   └── tun
        │       │   └── urandom
        │       ├── firecracker
        │       └── rootfs.ext4
        │       └── run
        │           └── firecracker.socket
        │       └── vmlinux-5.10-x86_64.bin
    ```

## Seccomp