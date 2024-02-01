#!/bin/bash
# Integration tests for cliqemu
# Tests One
#  - Mac Apple Silicon create debian box and destroy
#

last_output=""

function pushd () {
    command pushd "$@" > /dev/null
}

function popd () {
    command popd "$@" > /dev/null
}

function _test {
    echo -n -e "[\033[0;34mTEST\033[0m] $@... "
}

function _skip {
    echo -e "\033[0;33mSKIPPED\033[0m"
}

function _fail {
    echo -e "\033[0;31mFAILED\033[0m"
    exit 1
}

function _succeed {
    echo -e "\033[0;32mSUCCESS\033[0m"
}

function _precondition {
    if [ "$1" == "os" ]; then
        if [ "$(uname -s)" == "$2" ]; then return 0; else return 1; fi
    fi
    if [ "$1" == "arch" ]; then
       if [ "$(uname -m)" == "$2" ]; then return 0; else return 1; fi
    fi
}

function _run {
    last_output="$($@ 2>&1; exit $?)"
    [[ $? -eq 0 ]] && _succeed || _fail
}

function test_1_1 {
    _precondition "os" "Darwin" || return 100
    _precondition "arch" "arm64" || return 100

    _test "Create new Debian 12 image"
    _run ./vm new templates/darwin/arm64/debian12.vmt
    local vmname="$(echo "$last_output" | head -n 1 | cut -d '[' -f 2 | cut -d ']' -f 1)"

    _test "Run image"
    _run ./vm run $vmname

    _test "Wait 20 seconds for image to boot"
    _run sleep 20

    _test "Run command inside instance"
    _run ./vm ssh $vmname uname -s

    _test "Validate we are on a linux system"
    _run test "$last_output" == "Linux"

    _test "Stop image"
    _run ./vm stop $vmname

    _test "Cleanup"
    _run rm -Rf  $vmname
}

pushd ..
test_1_1 || _skip
popd
