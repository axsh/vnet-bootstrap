#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)" 1>&2
    exit 255
}

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path

checkok()
{
    echo "Checking sha1sum of $(readlink -f "$1")  ...."
    if [[ "$(sha1sum "$1")" == a158bd4694c845d684a9e59c5d0515ba738ea946* ]]
    then
	echo "Was downloaded sucessfully, sha1sum matches a158bd4694c845d684a9e59c5d0515ba738ea946"
	return 0
    else
	echo "Download failed."
    fi
}

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

# (also check in ~/potter in case you use the same machine as me and
#  I have already downloaded the iso)
if isofile="$(search-up-path "$fname" "$SCRIPT_DIR/../lib/c-dinkvm")" || \
    isofile="$(search-up-path "$fname" "/home/potter/isos")" || \
    isofile="$(search-up-path "$fname" ~/isos)"
then
    if ! checkok "$isofile"
    then
	echo "Should probably remove this file and run script again."
	exit
    fi
else
    echo "OK to download 1.7GB Centos ISO file to" ~/ "  ? (y/n)"
    read ans
    [[ "$ans" != y* ]] && exit

    cd ~/
    wget http://mirror.symnds.com/distributions/CentOS-vault/6.4/isos/x86_64/CentOS-6.4-x86_64-LiveDVD.iso
    isofile="$(pwd)/CentOS-6.4-x86_64-LiveDVD.iso"
    checkok "$isofile" || exit
fi

rm -f "$SCRIPT_DIR/../lib/CentOS-6.4-x86_64-LiveDVD.iso"
ln -s "$(readlink -f "$isofile")" "$SCRIPT_DIR/../lib/CentOS-6.4-x86_64-LiveDVD.iso"
