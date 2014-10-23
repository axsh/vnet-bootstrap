#!/bin/bash

[ -d ./lib/vnet-install-script ] || reportfail "expect to be run from grandparent dir of .../vnet-install-script/"
[ -d ./lib/c-dinkvm ] || reportfail "expect to be run from grandparent dir of .../c-dinkvm/"

source ./lib/processgroup-error-handler.source

config_path="$SCRIPT_DIR/../demo.config"
[ -f "$config_path" ] && reportfail "demo.config already exists.  Delete it manually, 
and probably also any VMs and snapshots that depend on it"


output-local-config()
{
    cat <<EOF
CODESOURCE=git

STAGES="boot pregit install full"

MEM_1=2000
boot_1=just_boot
pregit_1=local_pregit
install_1=part_2_start_vms_services
full_1=local_demo_setup
EOF
}


output-integration-test-config()
{
    cat <<EOF
CODESOURCE=git

STAGES="boot pregit install configure full"

MEM_r=1400
boot_r=just_boot
pregit_r=dev_git_yum_install
install_r=testspec_gems
full_r=router_demo_setup
EOF
    for i in 1 2 3; do
	cat <<EOF

MEM_$i=2000
boot_$i=just_boot
pregit_$i=vm123_pregit
install_$i=part_1_download_install_everything
full_$i=itests_env_setup
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
	output-local-config >"$config_path"
	;;
    itest)
	output-integration-test-config >"$config_path"
	;;
    *)
	usage
	;;
esac
