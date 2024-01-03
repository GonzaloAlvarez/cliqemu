#!/bin/bash
##
# Logic for Darwin ARM64 images that deploy with macosvm (darwin)
##

function check_dependencies {
    if [ ! -x "${CACHE_PATH}/macosvm" ]; then
        MACOSVM_URL="https://github.com/s-u/macosvm/releases/download/0.2-1/macosvm-0.2-1-arm64-darwin21.tar.gz"
        MACOSVM_TARGZ="${CACHE_PATH}/$(basename $MACOSVM_URL)"
        _cache_download "$MACOSVM_URL"
        $(which tar) -xf "$MACOSVM_TARGZ" -C "${CACHE_PATH}"
        rm -f "$MACOSVM_TARGZ"
    fi
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
    img="${VMIMG_FILE}"

    cp -c "${CACHE_PATH}/${vmimg}" ./$img

    ${CACHE_PATH}/macosvm --disk disk.img,size=50g --aux aux.img --restore "$vmimg" -c 4 -r 8589934592 vm.json

    cat << EOF > variables.sh
target=darwin
EOF
}

function _run_vm {
    [[ -d "$1" ]] || _fail "That's not an available VM number. Use ./vm list"
    cd "$1"
    shift 3
    ${CACHE_PATH}/macosvm -g vm.json
}
