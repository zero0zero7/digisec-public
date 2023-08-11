# Snapshotting

## To take a full snapshot of a jailed Firecracker uVM
This generates a *mem_file* and a *snapshot_file* in the root of the uVM.
```
./src/snapshot.sh -s <vm_id>
```

## To load the full snapshot to a new non-jailed Firecracker process
1) Launch a new (non-jailed) Firecracker process.
    It's socket file would be stored in the sockets/ directory
2) A read-write ext4 would also be generated and sotred in the root directory locally. <br>
This is needed because the snapshot indicates that there is such a disk in the priginal uVM's root and hence Firecracker would look for such a disk in the new uVM's root (which is by default the local / dir)
```
./src/run0.sh <new_vm_id>
./src/snapshot.sh -l <snapshot_vm_id> -n <new_vm_id>
```