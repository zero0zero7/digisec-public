# Steps to make a root file system 

1. Create and Mount rootfs
    1. Create empty ext4 file system image of desirable size
    2. Mount rootfs onto local directory

<br>

2. Mount rootfs onto Docker Alpine Linux container to load packages
    entrypoint is set to run ./set-rootfs.sh
    - Use apk to install packages
    - Configure network interface, user permissions and file capabilities
    - Copy root directory of container onto the rootfs
    - Build OpenRC services and start these services automatically via init scripts.


<br>

#### Sequence of scripts called
build-rorootfs <br>
--> docker/roset-rootfs <br>
--- --> docker/apk-install <br>
--- --> docker/roapply