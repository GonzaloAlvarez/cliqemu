#!/bin/bash
##
# Common logic for all linux hosts and architectures
##

cloudimg="${CACHE_PATH}/seed.img"

function __nocloud_setup {
    rm -f "${CACHE_PATH}/user-data"
    rm -f "${CACHE_PATH}/meta-data"

    __write_userdata
    __write_metadata

    # Generate the user data
    $(which genisoimage) -output seed.iso -volid cidata -joliet -rock "user-data" "meta-data"
}

function _new_vm {
    VM_PATH="VM${RND:-6}"
    mkdir "$VM_PATH"
    source "$1"
    cd "$VM_PATH"
    echo "New image id [$VM_PATH]"

    VMIMG_FILE="$(basename ${isourl})"
    _cache_download "$isourl"
    vmimg="${CACHE_PATH}/${VMIMG_FILE}"
    img="$(basename ${isourl}).qcow2"


    $(which qemu-img) create -F qcow2 -b "${vmimg}" -f qcow2 "$img"

    __nocloud_setup
    cat << EOF > variables.sh
IMAGE_FILE=$img
EOF
    cd ..
    echo "Completed. Image [$VM_PATH] built. Run ./vm run $VM_PATH to start it"
}

function _run_vm {
    [[ -d "$1" ]] || _fail "That's not an available VM number. Use ./vm list"
    cd "$1"
    source variables.sh
    shift
    $(which qemu-system-x86_64) \
        -cpu host -smp 2 -enable-kvm -m 4G -nographic \
        -object iothread,id=io1 -device virtio-rng-pci \
        -drive if=none,format=qcow2,file=${IMAGE_FILE},id=disk1 \
        -drive if=virtio,format=raw,file=seed.iso \
        -device virtio-blk,drive=disk1,bootindex=1,iothread=io1 \
        -device virtio-net-pci,netdev=net0 \
        -netdev user,id=net0,hostfwd=tcp::2200-:22,hostname=qemu
}
