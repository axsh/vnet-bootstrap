#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)" 1>&2
    exit 255
}

[ -d ./lib/vnet-install-script ] || reportfail "expect to be run from grandparent dir of .../vnet-install-script/"
[ -d ./lib/c-dinkvm ] || reportfail "expect to be run from grandparent dir of .../c-dinkvm/"

[ -f ../demo.config ] && reportfail "demo.config already exists.  Delete it manually, 
and probably any VMs and snapshots that depend on it at the same time"


output-local-config()
{
    cat <<EOF
STAGES="boot misc install configure full"

MEM-1=2000
boot-1=boot
misc-1=ttd
intall-1=ttd
configure-1=local_demo_setup
full-1=local_demo_setup
EOF
}


output-integration-test-config()
{
    cat <<EOF
STAGES="boot misc install configure full"

MEM-r=1400
boot-r=boot
misc-r=ttd
intall-r=ttd
configure-r=router_demo_setup
full-r=router_demo_setup
EOF
    for i in 1 2 3; do
	cat <<EOF
MEM-$i=1400
boot-$i=boot
misc-$i=ttd
intall-$i=ttd
configure-$i=itests_env_setup
full-$i=itests_env_setup
EOF
    done
}


usage()
{
    cat <<EOF
Takes one parameter which is either:
   local   - for a one machine openvnet demo
or
   itest   - for a clone of the intergration test environment
EOF
}

case "$1" in
    local)
	output-local-config >../demo.config
	;;
    itest)
	output-integration-test-config >../demo.config
	;;
    *)
	usage
	;;
esac
