#!/bin/bash

reportfail()
{
    echo "Failed...exiting. ($*)" 1>&2
    exit 255
}

set -e

export SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path

[ -d testdir ] && reportfail "testdir already exists"

if $(git status 1>/dev/null 2>/dev/null)
then
    reportfail "Do not run with current directory set to a directory that is in a git repository"
fi

cat <<EOF
This script will make new directory at $(pwd)/testdir and then
do the following in that directory:

(1) clone vnet-from-scratch repository
(2) run setup scripts
(3) start all VMs with latest https://github.com/axsh/openvnet-testspec.git
    and https://github.com/axsh/openvnet.git
(4) execute './itest-spec run simple'

OK? (y/n)
EOF

read ans
case "$ans" in
    y* | Y*)
	:
	;;
    *)
	echo "Exiting."
	exit
	;;
esac

mkdir testdir
cd testdir
git clone "$(cd "$SCRIPT_DIR/.." ; pwd -P)"
cd vnet-from-scratch
./bin/setup-0-download-centos-iso.sh
sudo ./bin/setup-1-modify-boot-ramdisk.sh
./bin/setup-2-cache-sbuml-resources.sh
./bin/setup-3-optional-preload-of-yum-and-gem-caches.sh
./bin/start-all-vms.sh -wait
./bin/itest-run-simple.sh -yes
