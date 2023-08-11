#!/bin/bash
set -x

unset ACTION
mkdir -p ./snapshots
mkdir -p ./mems

CUR_DIR="$(pwd)"


main() {
    while getopts 's:l:n:p:r:' c
    do
    case $c in
        s)
        ACTION=SNAPSHOT 
        # VM_ID=$OPTARG
        snapshot "$OPTARG";;
        l) 
        ACTION=LOAD 
        OLD=$OPTARG;;
        n)
        NEW_SELECTED=1
        NEW=$OPTARG;;
        p)
        ACTION=PAUSE
        pause "$OPTARG";;
        r)
        ACTION=RESUME
        pause "$OPTARG";;
    esac

    if [[ $ACTION == LOAD && $NEW_SELECTED -gt 0 ]];
    then load $NEW $OLD
    fi

    done

}



generate_issue_data() {
cat <<EOF
{
    "snapshot_path": "./snapshots/$snapshot",
    "mem_backend": {
        "backend_path": "./mems/$mem",
        "backend_type": "File"
    },
    "enable_diff_snapshots": false,
    "resume_vm": true
}

EOF
}


pause() {
    VM_ID=$1
    printf "Pausing\n"
    sudo curl --unix-socket "/jailer/firecracker/$VM_ID/root/run/firecracker.socket" -i \
    -X PATCH 'http://localhost/vm' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
        "state": "Paused"
    }'
}

resume(){
    VM_ID=$1
    printf "Resuming\n"
    sudo curl --unix-socket "/jailer/firecracker/$VM_ID/root/run/firecracker.socket" -i \
    -X PATCH 'http://localhost/vm' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
        "state": "Resumed"
    }'
}


snapshot() {
    VM_ID=$1
    echo "id: $VM_ID"

    # Pause
    pause $VM_ID

    # Full
    # snapshot_file and mem_file would be stored in the VM's chroot
    printf "Snapping\n"
    sudo curl --unix-socket "/jailer/firecracker/$VM_ID/root/run/firecracker.socket" -i \
    -X PUT 'http://localhost/snapshot/create' \
    -H  'Accept: application/json' \
    -H  'Content-Type: application/json' \
    -d '{
        "snapshot_type": "Full",
        "snapshot_path": "./snapshot_file",
        "mem_file_path": "./mem_file",
        "version": "1.1.0"
    }'

    # Resume
    # resume $VM_ID
}


load() {
    echo "new: $1  old:$2"
    snapshot="from_${2}_snapshot_file"
    mem="from_${2}_mem_file"
    # Copy the snapshot files over to the new uVM
    # sudo cp /jailer/firecracker/$2/root/snapshot_file "/jailer/firecracker/$1/root/$snapshot"
    sudo cp /jailer/firecracker/$2/root/snapshot_file "./snapshots/$snapshot"
    sudo chmod 644 "./snapshots/$snapshot"
    # sudo cp /jailer/firecracker/$2/root/mem_file "/jailer/firecracker/$1/root/$mem"
    sudo cp /jailer/firecracker/$2/root/mem_file "./mems/$mem"
    sudo chmod 644 "./mems/$mem"
    sudo ip link del "tap$2"
    # Load
    # sudo curl --unix-socket  "/jailer/firecracker/$1/root/run/firecracker.socket" -i \
    sudo curl --unix-socket  "$CUR_DIR/sockets/firecracker$1.socket" -i \
    -X PUT 'http://localhost/snapshot/load' \
    -H  'Accept: application/json' \
    -H  'Content-Type: application/json' \
    -d "$(generate_issue_data)"
    
}



main "$@"; exit