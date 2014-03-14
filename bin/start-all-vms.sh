#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)"
    exit 255
}

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path
source "$SCRIPT_DIR/../lib/share-code.source"

"$R/lib/vnet-install-script/start-all.sh" "$@" 1 2 3 r
