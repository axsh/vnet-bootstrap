#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)"
    exit 255
}

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path
source "$SCRIPT_DIR/../lib/shared-code.source"

set -e

ccc=0
if [ -d snapshots ]
then
    while [ -d snapshots-$(( ++ccc )) ] ; do sleep 0.2 ; done
    mv snapshots snapshots-$ccc
fi
mkdir snapshots

for v in vm*
do
    ./lib/c-dinkvm/dinkvm -save $v snapshots/snapshot-$v &
done

time wait
