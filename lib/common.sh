#!/bin/bash
##
# Common logic for all hosts and branching sourcing
##

[[ "$CACHE_PATH" ]] || CACHE_PATH="${MASTER_DIR}/.cache"
[[ -d "$CACHE_PATH" ]] || mkdir -p $CACHE_PATH
((RND=RANDOM<<15|RANDOM))

_isfunction() { declare -F -- "$@" >/dev/null; }

function _fail {
    echo "$@"
    exit;
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

    _isfunction "check_dependencies" && check_dependencies;
}

function _cache_download() {
    FILENAME_URL="$(basename $1)"
    [[ -f "$CACHE_PATH/$FILENAME_URL" ]] || (cd $CACHE_PATH; $(which curl) -LkO "$1")
}

