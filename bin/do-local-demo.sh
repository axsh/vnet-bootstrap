#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)"
    exit 255
}

export PWD="$(pwd)"
export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path
export R="$SCRIPT_DIR/.."
export DINKVM="$R/lib/c-dinkvm/dinkvm"

[ -d "$R/lib/vnet-install-script" ] && \
    [ -d "$R/lib/c-dinkvm" ] || reportfail "Directory layout is not correct"


if [ -d vm1 ]
then
    echo "Remove vm1 first?"
    read ans
    case "$ans" in
	y* | Y*)
	    "$DINKVM" -rm vm1
	;;
    esac
fi

time "$DINKVM" vm1 -mem 2000 -show ... sudo bash onhost/vnet-install-script/test-vnet-in-dinkvm.sh do -- git 1 "$@"

