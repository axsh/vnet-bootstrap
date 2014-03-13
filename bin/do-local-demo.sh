#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)"
    exit 255
}

[ -d vnet-install-script ] || reportfail "expect to be run from parent dir of .../vnet-install-script/"
[ -d lib/c-dinkvm ] || reportfail "expect to be run from grandparent dir of .../c-dinkvm/"

if [ -d vm1 ]
then
    echo "Remove vm1 first?"
    read ans
    case "$ans" in
	y* | Y*)
	    ./lib/c-dinkvm/dinkvm -rm vm1
	;;
    esac
fi

time ./lib/c-dinkvm/dinkvm vm1 -mem 2000 -show ... sudo bash onhost/vnet-install-script/test-vnet-in-dinkvm.sh do -- git 1 "$@"

