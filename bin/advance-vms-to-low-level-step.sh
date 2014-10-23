#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)" 1>&2
    exit 255
}

[ -d ./lib/vnet-install-script ] || reportfail "expect to be run from grandparent dir of .../vnet-install-script/"
[ -d ./lib/c-dinkvm ] || reportfail "expect to be run from grandparent dir of .../c-dinkvm/"

source ./lib/processgroup-error-handler.source

config_path="$SCRIPT_DIR/../demo.config"
[ -f "$config_path" ] || reportfail "demo.config file must be created with ./bin/initialize-demo-configuration"
source  "$config_path"  # only read in here for MEM_{1,2,3,r} parameters

divider()
{
    echo
    echo =============================================================================
    echo =============================================================================
    echo
}

verfify-not-stopped()
{
    sleep 0.5
    # if ./bin/stop-all-vms.sh removes a VM, don't restart it automatically
    [ -d vm$vmid ] || reportfail "Stopping because vm$vmid apparently forcibly removed."
}

do-until-done()
{
    vmid="$1"
    shift 1
    eval mem='$'MEM_$vmid
    local ccc=0
    echo $ccc >inprogress-$vmid
    while [ -f inprogress-$vmid ]
    do
	if [ -f "inprogress-$vmid.pid" ]
	then
	    claimer="$(< "inprogress-$vmid.pid")"
	    if [ -d "/proc/$claimer" ] # still alive
	    then
	        [ "$claimer" == "$$" ] || reportfail "There appears to be another start-all.sh running on vm$vmid"
	    fi
	fi
	echo "$$" >"inprogress-$vmid.pid"
	snapshot="" # parameter will be removed below during expansion (note: spaces in snapshot name not allowed)
	snset=""
	[ -d ../snapshots ] && snset="../snapshots"
	[ -d ./snapshots ] && snset="./snapshots"

	[ -d $snset/snapshot-all ] && snapshot=$snset/snapshot-all
	[ -d $snset/snapshot-vm$vmid ] && snapshot=$snset/snapshot-vm$vmid

	echo $(( ++ccc )) >inprogress-$vmid
	divider >>log$vmid
	time ./lib/c-dinkvm/dinkvm -mem "$mem"  $snapshot vm$vmid ... sudo env VMROLE=$vmid bash  \
	     onhost/lib/vnet-install-script/test-vnet-in-dinkvm.sh do "$@" &
	echo "$!" >pid$vmid
	sleep 2
	wait
	verfify-not-stopped
	# (check1 does not need the config vars)
	result="$(./lib/c-dinkvm/dinkvm -mem "$mem" vm$vmid ... sudo env VMROLE=$vmid bash  \
	    onhost/lib/vnet-install-script/test-vnet-in-dinkvm.sh check1 "$@" &
            )"
	if [[ "$result" != *Not* ]]
	then
	    echo "Success after $(cat inprogress-$vmid 2>/dev/null) attempts for vm$vmid." >>log$vmid
	    rm inprogress-$vmid inprogress-$vmid.pid
	else
	    echo "About to try again for vm$vmid...." 1>&2
	    sleep 10 # to avoid hogging CPU if things go really bad
	fi
	verfify-not-stopped
    done
}
low_level_step="$1"
shift

for i in "$@"
do
    case "$i" in
	1 | 2 | 3 | r)
	    eval time do-until-done $i "$low_level_step"  >>log$i &
	    ;;
	*)
	    echo "bad parameter: $1" 1>&2
	    sleep 10
	    ;;
    esac
done
