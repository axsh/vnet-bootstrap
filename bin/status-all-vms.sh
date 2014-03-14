#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)"
    exit 255
}

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path
source "$SCRIPT_DIR/../lib/share-code.source"

for i in 1 2 3 r
do
    [ -f inprogress-$i ] && echo "Attempts for vm$i: $(cat inprogress-$i 2>/dev/null)"
    if out="$([ -f pid$i ] && ps $(< pid$i) )"
    then
	echo "vm$i : $out"
    fi
done
