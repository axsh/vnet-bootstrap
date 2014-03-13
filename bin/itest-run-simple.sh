#!/bin/bash

# note: the simple test passes when run against these commits:
# ./vnet-install-script/start-all.sh 50f9e 07ed9a 1 2 3 r

reportfail()
{
    echo "Failed...exiting. ($*)"
    exit 255
}

[ -d ./vnet-install-script ] || reportfail "expect to be run from parent dir of .../vnet-install-script/"
[ -d ./lib/c-dinkvm ] || reportfail "expect to be run from parent dir of .../c-dinkvm/"

echo "Are you sure everything is ready to go?"

read ans

case "$ans" in
    y* | Y*)
	./lib/c-dinkvm/dinkvm vmr ... 'sudo bash -c "cd /opt/axsh/openvnet-testspec/bin && source /tmp/rubypath.sh && ./itest-spec run simple"'
	;;
esac
