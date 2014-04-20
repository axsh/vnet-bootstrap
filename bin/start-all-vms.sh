#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)" 1>&2
    exit 255
}

# TODO, do a pull from local git clones here??

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path
source "$SCRIPT_DIR/../lib/shared-code.source"

"$R/lib/vnet-install-script/start-all.sh" "$@" 1 2 3 r
