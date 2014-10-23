#!/bin/bash

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || exit
source "$SCRIPT_DIR/../lib/processgroup-error-handler.source"

# TODO, do a pull from local git clones here??
source "$SCRIPT_DIR/../lib/shared-code.source"

[ -d ./lib/vnet-install-script ] || reportfail "expect to be run from grandparent dir of .../vnet-install-script/"
[ -d ./lib/c-dinkvm ] || reportfail "expect to be run from grandparent dir of .../c-dinkvm/"

config_path="$SCRIPT_DIR/../demo.config"
[ -f "$config_path" ] || reportfail "demo.config file must be created with ./bin/initialize-demo-configuration"
source  "$config_path"  # only read in here for MEM_{1,2,3,r} parameters

divider()
{
    echo
    echo =============================================================================
    echo =============================================================================
    echo
}

for s in $STAGES; do
    high_level_stage="$s"
    [ "$high_level_stage" = "$1" ] && break
done
[ "$high_level_stage" = "$1" ] || reportfail "First parameter must be one of: $STAGES"
shift

# default to all VMs
if [ "$*" = "" ]; then
    vmlist=( 1 2 3 r )
else
    vmlist=( "$@" )
fi

for i in "${vmlist[@]}"; do
    case "$i" in
	1 | 2 | 3 | r)
	    eval "./bin/advance-vms-to-low-level-step.sh \$${high_level_stage}_$i $i"
	    ;;
	*)
	    sleep 5  # increase the chance of other messages moving out of the way
	    echo "bad parameter: $1" 1>&2
	    sleep 5
	    ;;
    esac
done
