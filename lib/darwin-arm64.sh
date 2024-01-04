#!/bin/bash
##
# Logic for Darwin ARM64 images that deploy with qemu
##

function _new_vm {
    [[ -f "$1" ]] || _fail "Potential templates: $(ls -R1 templates)"
    VM_PATH="VM${RND:-6}"
    mkdir "$VM_PATH"
    source "$1"
    cd "$VM_PATH"
    echo "New image id [$VM_PATH]"

    __new_efi 
