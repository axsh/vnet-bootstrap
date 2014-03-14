#!/bin/bash

# note: the simple test passes when run against these commits:
# ./vnet-install-script/start-all.sh 50f9e 07ed9a 1 2 3 r

reportfail()
{
    echo "Failed...exiting. ($*)"
    exit 255
}

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path
source "$SCRIPT_DIR/../lib/shared-code.source"

echo "Are you sure everything is ready to go?"

read ans

case "$ans" in
    y* | Y*)
	"$DINKVM" vmr ... 'sudo bash -c "cd /opt/axsh/openvnet-testspec/bin && source /tmp/rubypath.sh && ./itest-spec run simple"'
	;;
esac
