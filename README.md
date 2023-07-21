# Getting Started with Firecracker

## Prerequisites
Mainly, **Firecracker** and **KVM** must be present and accessible to user.
For more details, refer to [Firecracker documentation](https://github.com/firecracker-microvm/firecracker/blob/main/docs/getting-started.md)

## Kernel and Rootfs
- Custom Kernel with Internet connectivity
    ```
    ./src/build-kernel.sh
    ```
    Refer to /docs/kernel.md for explanation
- Custom Alpine Rootfs with Podman and dependencies installed
    ```
    ./src/build-rootfs.sh
    ```
    Refer to /docs/rootfs.md for explanation

## Starting Firecracker microVM
1) On terminal 1, at the directory where README.md is located, run *run0.sh*
2) On terminal 2, at the directory where README.md is located, run *run1.sh*
3) Without closing terminal 2, return to terminal 1 and login to the VM using "root" for both the username and password.
4) Run ```sh /fc/setup.sh```
5) Run ```podman run --rm -i alpine sh``` 
    Podman rootless container should also have internet access <br>
    *Note: Do NOT run podman with -t option, container would not be able to start*
    *Note: Do NOT run podman with --log-level option, container would not be able to start*