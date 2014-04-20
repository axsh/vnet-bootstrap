#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)" 1>&2
    exit 255
}

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path

abspath()
{
    p="$(dirname -- "$1")"
    f="$(basename -- "$1")"
    if absp="$(cd "$p"  2>/dev/null && pwd)"
    then
	echo "$absp/$f"
    else
	echo "$1" # keep same in case used in error message
	return 255
    fi
}

search-up-path()
{
    fname="$1"
    path="$(abspath "$2")"
    while [ "$path" != "" ]
    do
	if [ -f "$path/$fname" ]
	then
	    echo "$path/$fname"
	    return 0
	fi
	path="${path%/*}"
    done
    return 255
}

fname="CentOS-6.4-x86_64-LiveDVD.iso"  # TODO: generalize to 6.5, etc
bootdirname="boot-64-centos"

isofile="$(search-up-path "$fname" "$SCRIPT_DIR/../lib/c-dinkvm")" || reportfail "could not find $fname"

echo "Using ISO file at:  $isofile"
echo "(Usually this script takes about 15 seconds to run)"

cd "$SCRIPT_DIR/../lib/c-dinkvm"

rm -fr "$bootdirname"

sudo ./make-scriptable-kvm-knoppix.sh "$isofile" "$bootdirname"
sudo chown -R "$(id -un)":"$(id -un)" "$bootdirname"

echo "Finished.  If there was no other output, then probably everything is OK"
