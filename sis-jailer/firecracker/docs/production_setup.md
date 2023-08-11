# Production Setup

## Jailer
1. Execute src/jailer.sh in terminal A with root permissions. <br>
`./src/run-config.sh VM_ID` <br>
In this script, we set up a chroot jail at the <chroot_base> directory, and fire a microVM instance within that jail. This would result in a directory structure as below:
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
