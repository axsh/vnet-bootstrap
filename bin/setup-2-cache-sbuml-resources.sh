#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)"
    exit 255
}

set -e

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path

if [ -f "$SCRIPT_DIR/../sbuml-resources/sbuml-core-2424-1um-1sb-12-14-2012.tar.gz" ]
then
    echo "./sbuml-resources/sbuml-core-2424-1um-1sb-12-14-2012.tar.gz is already in place."
else
    cd "$SCRIPT_DIR/../sbuml-resources/"
    wget http://downloads.sourceforge.net/project/sbuml/core/2424-1um-1sb/sbuml-core-2424-1um-1sb-12-14-2012.tar.gz
fi
