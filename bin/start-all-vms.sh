#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)" 1>&2
    exit 255
}

# TODO, do a pull from local git clones here??

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path
source "$SCRIPT_DIR/../lib/shared-code.source"

dowait=0
rest=( )
parse_params()
{
    for p in "$@"
    do
	case "$p" in
	    *wait*)
		dowait=1
		;;
	    *)
		rest=( "${rest[@]}" "$p" )
		;;
	esac
    done
}


parse_params "$@"

"$R/lib/vnet-install-script/start-all.sh" "$rest[@]" 1 2 3 r

[ "$dowait" = "1" ] && "$SCRIPT_DIR/status-all-vms.sh" -wait
