#!/bin/bash
##
# Common logic for all hosts and branching sourcing
##

LIB_PATH="${MASTER_DIR}/lib"
[[ "$CACHE_PATH" ]] || CACHE_PATH="${MASTER_DIR}/.cache"
[[ -d "$CACHE_PATH" ]] || mkdir -p $CACHE_PATH
((RND=RANDOM<<15|RANDOM))

source "${LIB_PATH}/cloudinit.sh"

_isfunction() { declare -F -- "$@" >/dev/null; }

function _fail {
    echo "$@"
    exit;
}

function __index {
    [[ "$2" ]] || return 1
    value="$2"
    array_name="$1[@]"
    my_array=("${!array_name}")
    for i in "${!my_array[@]}"; do
        if [ "${my_array[$i]}" == "$value" ]; then
            printf '%s\n' "$i"
            return
        fi
    done
    return 1
}

function source_tree() {
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m)"

    if [ -f "${LIB_PATH}/${os}.sh" ]; then
        source "${LIB_PATH}/${os}.sh"
    fi

    if [ -f "${LIB_PATH}/${os}-${arch}.sh" ]; then
        source "${LIB_PATH}/${os}-${arch}.sh"
    fi

    if [ -f "$1" ]; then
        if [[ $1 == *.vmt ]]; then
            source "$1"
            if [ "$target" -a -f "${LIB_PATH}/${os}-${arch}-${target}.sh" ]; then
                source "${LIB_PATH}/${os}-${arch}-${target}.sh"
            fi
        fi
    fi
    if [ -d "$1" ]; then
        if [ -f "$1/variables.sh" ]; then
            source "$1/variables.sh"
            if [ "$target" -a -f "${LIB_PATH}/${os}-${arch}-${target}.sh" ]; then
                source "${LIB_PATH}/${os}-${arch}-${target}.sh"
            fi
        fi
    fi

    _isfunction "check_dependencies" && check_dependencies;
}

function _cache_download() {
    filename="$2"
    [[ -z "$filename" ]] && filename="$(basename $1)"
    if [ ! -f "$CACHE_PATH/$filename" ]; then
        pushd $CACHE_PATH
        $(which curl) -LkO "$1"
        [[ "$2" ]] && mv "${CACHE_PATH}/$(basename $1)" "${CACHE_PATH}/$2"
        popd
    fi
}

function __generate_sshkey() {
    if [ ! -f "sshkey" ]; then
        $(which ssh-keygen) -q -t rsa -b 4096 -N '' -C "email@qemu.vm" -f sshkey <<< $'\ny' >/dev/null 2>&1
    fi
}

function _ssh_vm() {
    [[ -d "$1" ]] || _fail "That's not an available VM number. Use ./vm list"
    cd "$1"
    source variables.sh
    shift

    $(which ssh) -i sshkey -l cliuser -o LogLevel=ERROR -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -p $SSH_PORT localhost $@
    cd ..
}

function _scp_vm() {
    [[ -d "$1" ]] || _fail "That's not an available VM number. Use ./vm list"
    local file=""
    local folder=""
    [[ -f "$2" ]] && file="$(cd "$(dirname -- "$2")" >/dev/null; pwd -P)/$(basename -- "$2")"
    [[ -d "$3" ]] && folder="$(cd $3 >/dev/null;pwd -P)"
    cd "$1"
    source variables.sh
    shift

    if [ -f "$file" -a -z "$2" ]; then
        $(which scp) -i sshkey -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -P $SSH_PORT "$file" cliuser@localhost:
    elif [ -d "$folder" -a -n "$1" ]; then
        $(which scp) -i sshkey -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -P $SSH_PORT cliuser@localhost:$1 "$folder"
    else
        _fail "That combination does not work"
    fi
}

__configs=( "disk.size" "display.mode" )
__configs_description=( "  disk.size [SIZE]                 Resize disk or increase. See qemu-img resize man page" \
                        "  display.mode [vnc|term|window]   Set the display mode. VNC is default" )
__configs_functions=( _resize_disk _display_mode )

function _config_vm() {
    [[ -d "$1" ]] || _fail "That's not an available VM number. Use ./vm list"
    cd "$1"
    source variables.sh
    shift

    if index=$(__index __configs $1); then
        shift
        ${__configs_functions[$index]} $@
    else
        echo "configuration key not found. These are the available configuration keys:"
        echo "Usage: "
        (IFS=$'\n'; echo "${__configs_description[*]}")
    fi

    cd ..
}

function _monitor_vm {
    [[ -d "$1" ]] || _fail "That's not an available VM number. Use ./vm list"

    cd "$1"
    $(which socat) -,echo=0,icanon=0 unix-connect:qemu-monitor-socket
    cd ..
}

function _list_vms {
    ls -1 VM* 2>/dev/null
    [[ $? -ne 0 ]] && echo "No machines found or permissions issue"
}

function __load_template {
    if [[ $(file -b --mime-type "$1") == 'text/plain'* ]]; then
        source $1
    elif [[ $(file -b --mime-type "$1") == 'application/x-bzip2'* ]]; then
        local template_name="$(basename "$1" | cut -d. -f1)"
        mkdir -p "$CACHE_PATH/$template_name"
        $(which tar) -xjf $1 -C "$CACHE_PATH/$template_name"
        source "$CACHE_PATH/$template_name/variables.sh"
        mv "$CACHE_PATH/$template_name/$isourl" "$CACHE_PATH"
        tar -xf "$CACHE_PATH/$template_name/extras.tar" -C "$2"
        mv "$CACHE_PATH/$template_name/sshkey" "$CACHE_PATH/$template_name/sshkey.pub" "$2"
    elif [[ $(file -b --mime-type "$1") == 'application/x-tar'* ]]; then
        local template_name="$(basename "$1" | cut -d. -f1)"
        mkdir -p "$CACHE_PATH/$template_name"
        $(which tar) -xf $1 -C "$CACHE_PATH/$template_name"
        source "$CACHE_PATH/$template_name/variables.sh"
        mv "$CACHE_PATH/$template_name/$isourl" "$CACHE_PATH"
        tar -xf "$CACHE_PATH/$template_name/extras.tar" -C "$2"
        mv "$CACHE_PATH/$template_name/sshkey" "$CACHE_PATH/$template_name/sshkey.pub" "$2"
    fi
}
