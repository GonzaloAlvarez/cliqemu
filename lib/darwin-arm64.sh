#!/bin/bash
##
# Logic for Darwin ARM64 images that deploy with qemu
##

efi32_uri="https://releases.linaro.org/components/kernel/uefi-linaro/16.02/release/qemu64/QEMU_EFI.fd"
efi64_uri="http://snapshots.linaro.org/components/kernel/leg-virt-tianocore-edk2-upstream/4919/QEMU-AARCH64/RELEASE_GCC5/QEMU_EFI.fd"
efi32_name="qemu_efi_32.fd"
efi64_name="qemu_efi_64.fd"

function __setup_efi {
    if [ "$efi_arch" == "32" ]; then
        _cache_download $efi32_uri $efi32_name
        cp "$CACHE_PATH/$efi32_name" QEMU_EFI.fd
    else
        _cache_download $efi64_uri $efi64_name
        cp "$CACHE_PATH/$efi64_name" QEMU_EFI.fd
    fi
    dd if=/dev/zero of=flash0.img bs=1m count=64 status=none
    dd if=QEMU_EFI.fd of=flash0.img conv=notrunc status=none
    dd if=/dev/zero of=flash1.img bs=1m count=64 status=none
    rm -f QEMU_EFI.fd
}

function __setup_cloudinit {
    __generate_sshkey
    __write_userdata
    __write_metadata

    mkdir cloudinit
    mv meta-data user-data cloudinit/
    $(which hdiutil) makehybrid -o cloud.iso -joliet -iso -default-volume-name cidata cloudinit
    $(which qemu-img) convert cloud.iso -O qcow2 cloud.qcow2
}

function _new_vm {
    [[ -f "$1" ]] || _fail "Potential templates: $(ls -R1 templates)"
    VM_PATH="VM${RND:-6}"
    mkdir "$VM_PATH"
    source "$1"
    cd "$VM_PATH"
    echo "New image id [$VM_PATH]"

    __setup_efi
    __setup_cloudinit

    _cache_download "$isourl"
    vmimg="${CACHE_PATH}/$(basename ${isourl})"
    img="$(basename ${isourl}).qcow2"

    $(which qemu-img) create -F qcow2 -b "${vmimg}" -f qcow2 "$img"

    cat << EOF > variables.sh
IMAGE_FILE=${img}
SSH_PORT=$((2222 + $RANDOM % 200))
display="-display vnc=unix:vnc.socket -daemonize"
EOF
}

function _resize_disk {
    $(which qemu-img) resize "$IMAGE_FILE" $1
}

function _display_mode {
    if [ "$1" == "vnc" ]; then
        echo 'display="-display vnc=unix:vnc.socket -daemonize"' >> variables.sh
    elif [ "$1" == "term" ]; then
        echo 'display="-nographic"' >> variables.sh
    elif [ "$1" == "window" ]; then
        echo 'display=""' >> variables.sh
    else
        echo "Only vnc, term or window are valid values"
        return
    fi
}

function _stop_vm {
    [[ -d "$1" ]] || _fail "That's not an available VM number. Use ./vm list"

    cd "$1"
    echo "quit" | socat unix-connect:qemu-monitor-socket -
    cd ..
}

function _run_vm {
    [[ -d "$1" ]] || _fail "That's not an available VM number. Use ./vm list"
    cd "$1"
    source variables.sh
    shift
    export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
    $(which qemu-system-aarch64) -m 4096 -smp 2 -cpu cortex-a57 -M virt \
        -name "$1" $display \
        -accel hvf \
        -monitor unix:qemu-monitor-socket,server,nowait \
        -drive if=pflash,file=flash0.img,format=raw \
        -drive if=pflash,file=flash1.img,format=raw \
        -drive if=none,file=$IMAGE_FILE,id=hd0 \
        -device virtio-blk-device,drive=hd0 \
        -drive if=none,id=cloud,file=cloud.qcow2 \
        -device virtio-blk-device,drive=cloud \
        -device virtio-net-device,netdev=user0 \
        -netdev user,id=user0,hostfwd=tcp::$SSH_PORT-:22
}
