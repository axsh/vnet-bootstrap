#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)"
    exit 255
}

[ -d vnet-install-script ] || reportfail "expect to be run from parent dir of .../vnet-install-script/"
[ -d c-dinkvm ] || reportfail "expect to be run from parent dir of .../c-dinkvm/"

for i in 1 2 3 r
do
    [ -f inprogress-$i ] && echo "Attempts for vm$i: $(cat inprogress-$i 2>/dev/null)"
    if out="$([ -f pid$i ] && ps $(< pid$i) )"
    then
	echo "vm$i : $out"
    fi
done
