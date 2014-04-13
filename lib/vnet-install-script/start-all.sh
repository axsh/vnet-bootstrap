#!/bin/bash


reportfail()
{
    echo "Failed...exiting. ($*)"
    exit 255
}

[ -d ./lib/vnet-install-script ] || reportfail "expect to be run from grandparent dir of .../vnet-install-script/"
[ -d ./lib/c-dinkvm ] || reportfail "expect to be run from grandparent dir of .../c-dinkvm/"

divider()
{
    echo
    echo =============================================================================
    echo =============================================================================
    echo
}

verfify-not-stopped()
{
    # if ./bin/stop-all-vms.sh removes a VM, don't restart it automatically
    [ -d vm$vmid ] || reportfail "Stopping because vm$vmid apparently forcibly removed."
}

do-until-done()
{
    vmid="$1"
    mem="$2"
    shift 2
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
	time ./lib/c-dinkvm/dinkvm -mem "$mem"  $snapshot vm$vmid ... sudo bash  \
	     onhost/lib/vnet-install-script/test-vnet-in-dinkvm.sh do "$@" &
	echo "$!" >pid$vmid
	sleep 2
	wait
	verfify-not-stopped
	result="$(./lib/c-dinkvm/dinkvm -mem "$mem" vm$vmid ... sudo bash  \
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

for i in "$@"
do
    case "$i" in
	1 | 2 | 3)
	    time do-until-done $i 2000 itests_env_setup -- git $i >>log$i $vnetcommit &
	    ;;
	r*)
	    time do-until-done $i 1400 router_demo_setup -- git r >>log$i $testcommit &
	    echo "$!" >pid$i
	    ;;
	*)
	    if [ "$vnetcommit" == "" ]
	    then
		vnetcommit="$i"
	    elif [ "$testcommit" == "" ]
	    then
		testcommit="$i"
	    else
		echo "bad parameter: $1" 1>&2
		sleep 10
	    fi
	    ;;
    esac
done

for i in 1 2 3 r
do
    [ -f inprogress-$i ] && echo "Attempts for vm$i: $(cat inprogress-$i 2>/dev/null)"
    if out="$([ -f pid$i ] && ps $(< pid$i) )"
    then
	echo "vm$i : $out"
    fi
done
