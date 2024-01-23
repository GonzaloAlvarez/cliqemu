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
    local -n my_array=$1 # use -n for a reference to the array
    for i in "${!my_array[@]}"; do
    if [[ ${my_array[i]} = $2 ]]; then
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

__configs=( "disk.size" )
__configs_description=( "disk.size [SIZE]         Resize disk or increase. See qemu-img resize man page" )
__configs_functions=( _resize_disk )

function _config_vm() {
    [[ -d "$1" ]] || _fail "That's not an available VM number. Use ./vm list"
    cd "$1"
    source variables.sh
    shift

    if index=$(__index __configs $1); then
        shift
        __configs_functions[$index] $@
    else
        echo "configuration key not found. These are the available configuration keys:"
        echo "Usage: "
        (IFS=$'\n'; echo "    ${__configs_description[*]}")
    fi

    cd ..
}
