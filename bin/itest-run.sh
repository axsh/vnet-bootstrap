#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)" 1>&2
    exit 255
}

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path
source "$SCRIPT_DIR/../lib/shared-code.source"

echo "About to execute ./itest-spec run $*"
echo -n "...but sleeping for 10 seconds first to give you a change to ^C..."
sleep 10
echo "here we go!

case "$ans" in
    y* | Y*)
	"$DINKVM" vmr ... 'sudo bash -c "cd /opt/axsh/openvnet-testspec/bin && source /tmp/rubypath.sh && ./itest-spec run "$*"'"'
	;;
esac
