# Getting Started with Firecracker

## Prerequisites
Mainly, **Firecracker** and **KVM** must be present and accessible to user.
For more details, refer to [Firecracker documentation](https://github.com/firecracker-microvm/firecracker/blob/main/docs/getting-started.md)

## Firecracker
Clone Firecracker repository and modify its CPU string before building.
This is handled in the *src/build-kernel.sh* script via calling the script *src/firecracker-binary.sh*


## Rootfs and Kernel
### Root File System
Custom Alpine rootfs with Podman and dependencies installed
 ```
./src/build-rorootfs.sh [size (default 3000MB)]
```
Refer to /docs/rootfs.md for explanation

### Kernel
```
./src/build-kernel.sh [path to firecracker repo]
```
Refer to /docs/kernel.md for explanation


## Starting Firecracker microVM
1) At the directory where README.md is located 
    ```
    src/run-config.sh [VM ID]
    ```
    *Note: Firecracker uVM configurations are defined in src/config.json*
2) The Firecracker uVM should be booted with Podman container launched. <br>

    *Note: Do NOT run podman with -t option, container would not be able to start* <br>
    *Note: Do NOT run podman with --log-level option, container would not be able to start*

3) *snapshot.sh* allows us to take whole snapshots of the uVM and also to restore the uVM from another Firecracker process. <br>
For safe restoration, **only 1** process running on the same snapshot should be running at any one time.