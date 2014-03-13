#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)"
    exit 255
}

[ -d ./vnet-install-script ] || reportfail "expect to be run from parent dir of .../vnet-install-script/"
[ -d ./lib/c-dinkvm ] || reportfail "expect to be run from parent dir of .../c-dinkvm/"

for i in 1 2 3 r
do
    [ -d vm$i ] && ./lib/c-dinkvm/dinkvm -rm vm$i
done
