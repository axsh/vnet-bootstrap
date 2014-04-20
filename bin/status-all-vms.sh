#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)"
    exit 255
}

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path
source "$SCRIPT_DIR/../lib/shared-code.source"

dowait=0
[[ "$*" == *wait* ]] && dowait=1

while [ "$dowait" = "1" ]
do
    alldone=1
    for i in 1 2 3 r
    do
	[ -f inprogress-$i ] && echo "Attempts for vm$i: $(cat inprogress-$i 2>/dev/null)"
	if out="$([ -f pid$i ] && ps $(< pid$i) )"
	then
	    alldone=0
	    echo "vm$i : $out"
	fi
    done
    if [ "$dowait" = "1" ]
    then
	if [ "$alldone" = "0" ]
	then
	    echo
	    echo -n "Waiting 30 seconds..."
	    sleep 30
	    echo "checking again:"
	    echo
	else
	    dowait=0
	fi
    fi
done
