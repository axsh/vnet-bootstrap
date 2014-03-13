#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)"
    exit 255
}

[ -d ./vnet-install-script ] || reportfail "expect to be run from parent dir of .../vnet-install-script/"
[ -d ./lib/c-dinkvm ] || reportfail "expect to be run from parent dir of .../c-dinkvm/"

./vnet-install-script/start-all.sh "$@" 1 2 3 r
