vnet-from-scratch
=================

Note: depends on a web server running on 2.24, so for now the
following will not work outside of the office.

## One time setup:


    ./bin/setup-0-download-centos-iso.sh


Downloads the LiveCD image.  If you run this on 2.24,
it will try to use the ISO image that is already downloaded there.



    ./bin/setup-1-modify-boot-ramdisk.sh
    ./bin/setup-2-cache-sbuml-resources.sh

Necessary steps.

    ./bin/setup-3-optional-preload-of-yum-and-gem-caches.sh

This changes the initial install from about 45 minutes to 10 or so minutes.


    ./bin/initialize-demo-configuration.sh itest

The "itest" parameter is necessary.  (There is also a "local" that
will start a one-machine OpenVNet demo.)

    ./bin/advance-vms-to-high-level-stage.sh full 1

Start out by installing to vm1 only.  In theory, this step should not
be necessary, however, the VMs share the same cache directories and
clobber each other the first pass through, so let one machine get
everything in order.  (TODO: The scripts should be changed to use locks and
be more careful.)  Anyway, one VM should work OK and take about 10 minutes.

Warning: You really must wait until vm1 is finished.  You can check
progress (or problems) with "tail -f log1".
"./vm1/vnetscript-shortcut.sh itests_env_setup" gives another useful
view of progress.


## Bootstraping and running a test:

    ./bin/advance-vms-to-high-level-stage.sh full

No machine number parameter given, so it defaults to all VMs.  Should
take about 5 minutes.


    ./bin/itest-run.sh simple


Does: /opt/axsh/openvnet-testspec/bin/itest-spec run simple.


    ./bin/stop-all-vms.sh


Kills all VMs in the cluster at $(pwd).


    ./bin/dinkvm -ls -rm


Kills all VMs currently started by the current user.


