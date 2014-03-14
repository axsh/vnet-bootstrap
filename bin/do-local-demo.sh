#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)"
    exit 255
}

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path
source "$SCRIPT_DIR/../lib/shared-code.source"

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

time "$DINKVM" vm1 -mem 2000 -show ... sudo bash onhost/lib/vnet-install-script/test-vnet-in-dinkvm.sh do -- git 1 "$@"
