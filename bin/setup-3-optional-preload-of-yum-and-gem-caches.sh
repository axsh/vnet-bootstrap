#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)"
    exit 255
}

set -e

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path

if [ -d "$SCRIPT_DIR/../var-cache-yum" ] || [ -d "$SCRIPT_DIR/../vnet-vendor" ]
then
    echo "var-cache-yum or vnet-vendor directories already exist."
    echo "do 'rm -fr var-cache-yum vnet-vendor' and run again for fresh cache preload."
else
    cd "$SCRIPT_DIR/.."
    curl http://192.168.2.26:2579/cache-v4.tar.gz | tar xz
fi
