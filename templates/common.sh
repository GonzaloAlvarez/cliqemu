#!/bin/bash
##
# Common logic for all hosts and branching sourcing
##

[[ "$CACHE_PATH" ]] || CACHE_PATH="${MASTER_DIR}/.cache"
[[ -d "$CACHE_PATH" ]] || mkdir -p $CACHE_PATH


_isfunction() { declare -F -- "$@" >/dev/null; }

function _fail {
    echo "$@"
    exit;
}

function source_host() {
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m)"

    if [ -f "${TEMPLATES_DIR}/${os}/common.sh" ]; then
        source "${TEMPLATES_DIR}/${os}/common.sh"
    fi

    if [ -f "${TEMPLATES_DIR}/${os}/${arch}/common.sh" ]; then
        source "${TEMPLATES_DIR}/${os}/${arch}/common.sh"
    fi

    _isfunction "check_dependencies" && check_dependencies;
}

function _cache_download() {
    FILENAME_URL="$(basename $1)"
    [[ -f "$CACHE_PATH/$FILENAME_URL" ]] || (cd $CACHE_PATH; $(which curl) -LkO "$1")
}

