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

do-until-done()
{
    vmid="$1"
    mem="$2"
    shift 2
    local ccc=0
    echo $ccc >inprogress-$vmid
    while [ -f inprogress-$vmid ]
    do
	snapshot=""
	[ -d snapshot-all ] && snapshot=snapshot-all
	[ -d snapshot-vm$i ] && snapshot=snapshot-vm$i
	echo $(( ++ccc )) >inprogress-$vmid
	divider >>log$vmid
	time ./lib/c-dinkvm/dinkvm -mem "$mem" vm$i ... sudo bash  \
	    onhost/lib/vnet-install-script/test-vnet-in-dinkvm.sh do "$@" &
	echo "$!" >pid$vmid
	sleep 2
	wait
	result="$(./lib/c-dinkvm/dinkvm -mem "$mem" vm$i ... sudo bash  \
	    onhost/lib/vnet-install-script/test-vnet-in-dinkvm.sh check1 "$@" &
            )"
	if [[ "$result" != *Not* ]]
	then
	    echo "Success after $(cat inprogress-$vmid 2>/dev/null) attempts for vm$vmid." >>log$vmid
	    rm inprogress-$vmid
	else
	    echo "About to try again for vm$vmid...." 1>&2
	    sleep 10 # to avoid hogging CPU if things go really bad
	fi
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
