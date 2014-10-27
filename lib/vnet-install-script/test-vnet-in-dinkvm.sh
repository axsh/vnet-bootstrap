#!/bin/bash

tmp=/home/centoslive/onhost/demo.config
[ -f $tmp ] && source $tmp

SBUMLRESOURCES="/home/centoslive/onhost/sbuml-resources"

reportfail()
{
    echo "Failed...exiting. ($*)" 1>&2
    exit 255
}

try()
{
    eval "$@" || reportfail "$@"
}

[ "root" = "$(whoami)" ] || reportfail "must be root"

# Note: the step to setup itest env for nodes 1,2, and 3
# is itests_env_setup

# Note: the step to setup itest env for router node is
# router_demo_setup

default_steps='
  all_steps
'

######## fake step: just_boot

# The purpose of this step is to give
# a target that does nothing, so the
# VM just boots.

deps_just_boot='
'

check_just_boot()
{
    true
}

do_just_boot()
{
    true
}

######## fake step: all_steps

# The purpose of this step is to give
# one target that summarizes all the
# tree/DAGs of steps in this file.

deps_all_steps='
  block
  local_pregit
  local_demo_setup
  router_demo_setup
  vm123_pregit
  itests_env_setup
'

check_all_steps()
{
    false
}

do_all_steps()
{
    false
}

######## fake step: block

# The purpose of this steps is so that it can
# be added to other fake steps to block them
# from trying to "do" their dependencies.

deps_block='
'
check_block()
{
    false
}

do_block()
{
    false
}

######## summary step: local_pregit

# define the pregit high-level stage for
# the local_demo config

deps_local_pregit='
  dev_git_yum_install
  add_local_test_taps_to_switch
'

# Note: not sure if add_itests_taps_to_switch can really be done
# before installing openvnet from github

check_local_pregit()
{
    [ -f /tmp/finished-local_pregit ]
}

do_local_pregit()
{
    touch /tmp/finished-local_pregit
}

######## summary step: vm123_pregit

# define the pregit high-level stage for
# the itests config

deps_vm123_pregit='
  dev_git_yum_install
  add_itests_taps_to_switch
  set_etc_wakame_vnet
'

# Note: not sure if add_itests_taps_to_switch can really be done
# before installing openvnet from github

check_vm123_pregit()
{
    [ -f /tmp/finished-vm123_pregit ]
}

do_vm123_pregit()
{
    touch /tmp/finished-vm123_pregit
}

######## summary step: part_1_download_install_everything

deps_part_1_download_install_everything='
  vnet_gems
  install_sbuml_core
'

check_part_1_download_install_everything()
{
    [ -f /tmp/finished-part-1 ]
}

do_part_1_download_install_everything()
{
    # just a wrapper to call the deps
    touch /tmp/finished-part-1
}

######## summary step: part_2_start_vms_services

deps_part_2_start_vms_services='
  start_sbuml_vms_for_local_test
  redis_mysql_restart
  openvswitch_restart
  network_restart
  vnet_restart
'

check_part_2_start_vms_services()
{
    [ -f /tmp/finished-part-2 ]
}

do_part_2_start_vms_services()
{
    # just a wrapper to call the deps
    touch /tmp/finished-part-2
}

######## summary step: part_3_configure_switch

deps_part_3_configure_switch='
  add_local_test_taps_to_switch
  populate_database_for_local_test
'

check_part_3_configure_switch()
{
    [ -f /tmp/finished-part-3 ]
}

do_part_3_configure_switch()
{
    # just a wrapper to call the deps
    touch /tmp/finished-part-3
}

######## verify_not_router

deps_verify_not_router='set_global_options'


check_verify_not_router()
{
    [[ "$VMROLE" != r* ]]
}

do_verify_not_router()
{
    : # just a wrapper
}

######## verify_is_router

deps_verify_is_router='set_global_options'


check_verify_is_router()
{
    [[ "$VMROLE" == r* ]]
}

do_verify_is_router()
{
    : # just a wrapper
}


######## testspec_install

deps_testspec_install='dev_git_yum_install'

check_testspec_install()
{
    [ -d /opt/axsh/openvnet-testspec/.git ]
}

do_testspec_install()
{
    mkdir -p /opt/axsh
    cd /opt/axsh
    if [ -d /home/centoslive/onhost/projects/openvnet-testspec/.git ]
    then
	git clone /home/centoslive/onhost/projects/openvnet-testspec
    else
	git clone https://github.com/axsh/openvnet-testspec.git
    fi

    (
	cd /opt/axsh/openvnet-testspec/
	[ "$COMMIT" != "" ] && git checkout "$COMMIT"

	# sleep more between starting vnet and using webapi to load dataset
	sed -i 's/sleep(3)/sleep(23)/' /opt/axsh/openvnet-testspec/lib/vnspec/invoker.rb
	# sleep between starting vna and doing DHCP in the VMs
	sed -i 's/VM.start_network/sleep(25) ; VM.start_network/' \
	    /opt/axsh/openvnet-testspec/lib/vnspec/invoker.rb
	
	mv /opt/axsh/openvnet-testspec/dataset/base.yml /tmp/base.yml
	{
	    while IFS= read -r ln ; do
		echo "$ln"
		[[ "$ln" == *if-dp3eth0* ]] && break
	    done
	    while IFS= read -r ln ; do
                # hopefully will change "port_name: eth0" to "port_name: eth3"
		# just for if-dp3eth0
		if [[ "$ln" == *port_name* ]]; then
		    echo "    port_name: eth3"
		    break
		fi
		echo "$ln"
	    done
	    cat # rest unchanged
	} </tmp/base.yml >/opt/axsh/openvnet-testspec/dataset/base.yml
    )
}

######## testspec_gems

deps_testspec_gems='
  misc_initialization
  testspec_install
'

check_testspec_gems()
{
    TESTSPEC_GEMS_RC="$(cat 2>/dev/null "$OPTS/testspec-gems-rc")"
    [ "$TESTSPEC_GEMS_RC" == 0 ] || return 255
}

do_testspec_gems()
{
    source /tmp/rubypath.sh
    cd /opt/axsh/openvnet-testspec/
    bundle install --without=development
    echo "$?" >"$OPTS/testspec-gems-rc"
}

######## router_demo_setup

deps_router_demo_setup='
  misc_initialization
  verify_is_router
  dev_git_yum_install
  testspec_gems
'

check_router_demo_setup()
{
    [ -f /tmp/finished-router-demo-setup ]
}

do_router_demo_setup()
{
    
    # TODO: deal with EDGE machine better
    sed -i 's/, 192.168.2.90//' /opt/axsh/openvnet-testspec/config/itest.yml
    # TODO: What is this new machine in the spec for???
    sed -i 's/, 192.168.2.95//' /opt/axsh/openvnet-testspec/config/itest.yml

    # to make secg test work:
    sed -i 's/ping -c 1/ping -c 1 -w 10/' /opt/axsh/openvnet-testspec/lib/vnspec/vm.rb
    sed -i 's/ssh_on_guest(cmd)\[:stdout\].chomp/ssh_on_guest(cmd)[:stdout].chomp ; sleep(2)/' /opt/axsh/openvnet-testspec/lib/vnspec/vm.rb

    # increase timeouts in vm.rb
#    sed -i 's/ConnectTimeout: 1}/ConnectTimeout: 20}/' /opt/axsh/openvnet-testspec/lib/vnspec/vm.rb
#    sed -i 's/timeout = 2)/timeout = 20)/' /opt/axsh/openvnet-testspec/lib/vnspec/vm.rb

    # This one should be changed in openvnet-testspec:
    # Use StrictHostKeyChecking for connecting to newly created guest VMs
    sed -i 's/#{config\[:ssh_user]}/-o StrictHostKeyChecking=no #{config[:ssh_user]}/' /opt/axsh/openvnet-testspec/lib/vnspec/vm.rb

    # Why was this ever in here? Commenting out now because it stopped local pings
    # and probably caused other problems.
    # service network stop

    service NetworkManager stop
    killall dhclient

    echo 1 >/proc/sys/net/ipv4/ip_forward

    ##  # be sure not to use same IP as virtual box host networking adapter

    ifconfig eth0 up 172.16.90.111 netmask 255.255.255.0


    ifconfig eth2 up 192.168.2.1 netmask 255.255.255.0  hw ether 02:01:00:00:22:99

    ifconfig eth3 up 172.16.91.111 netmask 255.255.255.0  hw ether 02:01:00:00:33:99

    touch /tmp/finished-router-demo-setup
}

######## local_demo_setup

deps_local_demo_setup='
  verify_not_router
  part_1_download_install_everything
  part_2_start_vms_services
  part_3_configure_switch
'

check_local_demo_setup()
{
    check_part_3_configure_switch && \
	check_part_2_start_vms_services && \
	check_part_1_download_install_everything
}

do_local_demo_setup()
{
    do_vnet_restart # will restart, even if already restarted
    
    sleep 15 # long sleep needed here
    bash /tmp/pingto1.sh  # file created by setup-sbuml
    bash /tmp/pingto2.sh  # file created by setup-sbuml

    sleep 15 # long sleep needed here
    bash /tmp/pingto1.sh  # file created by setup-sbuml
    bash /tmp/pingto2.sh  # file created by setup-sbuml
}

######## itests_env_setup

deps_itests_env_setup='
  verify_not_router
  part_1_download_install_everything
  redis_mysql_restart
  add_itests_taps_to_switch
  set_etc_wakame_vnet
'

check_itests_env_setup()
{
    [ -f /tmp/finished-itests-env-setup ]
}

do_itests_env_setup()
{
    # TODO, what is a clean way to do a fresh pull here?
    touch /tmp/finished-itests-env-setup
}

######## redis_mysql_restart

deps_redis_mysql_restart='
  misc_initialization
  vnet_gems
'

check_redis_mysql_restart()
{
    { service redis status &&  service mysqld status ; } >/dev/null 2>&1
}

do_redis_mysql_restart()
{
    source /tmp/rubypath.sh

    service redis stop
    service mysqld stop

    # allow vna from outside to connect
    sed -i 's/^bind/#bind/' /etc/redis.conf

    service redis start
    service mysqld start
    if ! echo | mysql -u root vnet
    then
	echo 'create database vnet;' | mysql -u root
    fi
    cd /opt/axsh/openvnet/vnet
    bundle exec rake db:init
}

######## openvswitch_restart

deps_openvswitch_restart='
  wakame_yum_install
  ifcfg_scripts
'

check_openvswitch_restart()
{
    service openvswitch status >/dev/null 2>&1
}

do_openvswitch_restart()
{
    modprobe openvswitch
    service openvswitch restart
}

######## network_restart

deps_network_restart='openvswitch_restart'

check_network_restart()
{
    [ -f /tmp/finished-network-restart ]
}

do_network_restart()
{
    service network restart

    case "$VMROLE" in
	1 | 2)
	    route add -net 172.16.91.0 netmask 255.255.255.0 gw 172.16.90.111
	    ;;
	3) 
	    route add -net 172.16.90.0 netmask 255.255.255.0 gw 172.16.91.111
	    ;;
    esac
    route add -host 192.168.2.24 gw 10.0.2.2  # for temporary SBUML http resources
    touch /tmp/finished-network-restart
}

######## vnet_restart

deps_vnet_restart='
  redis_mysql_restart
  openvswitch_restart
  network_restart
'

check_vnet_restart()
{
    [ -f /tmp/finished-vnet-restart ]
}

do_vnet_restart()
{
    stop vnet-vnmgr
    stop vnet-vna
    stop vnet-webapi
    
    start vnet-vnmgr
    start vnet-vna
    start vnet-webapi

    touch /tmp/finished-vnet-restart
}

######## add_local_test_taps_to_switch

deps_add_local_test_taps_to_switch='
  start_sbuml_vms_for_local_test
  openvswitch_restart
  network_restart
'

check_add_local_test_taps_to_switch()
{
    # TODO: really check
    [ -f /tmp/add_local_test_taps_to_switch ]
}

do_add_local_test_taps_to_switch()
{
    rm /tmp/add_*_taps_to_switch
    ovs-vsctl show | grep -o 'Port \"if.*' | while read ln
    do
	iname="${ln#Port \"}"
	iname="${iname%\"}"
	ovs-vsctl del-port br0 "$iname"
    done

    ovs-vsctl add-port br0 if-tap0
    ovs-vsctl add-port br0 if-tap1

    touch /tmp/add_local_test_taps_to_switch
}

######## add_itests_taps_to_switch

deps_add_itests_taps_to_switch='
  start_sbuml_vms_for_itests
  openvswitch_restart
  network_restart
'

check_add_itests_taps_to_switch()
{
    # TODO: really check
    [ -f /tmp/add_itests_taps_to_switch ]
}

do_add_itests_taps_to_switch()
{
    rm /tmp/add_*_taps_to_switch
    ovs-vsctl show | grep -o 'Port \"if.*' | while read ln
    do
	iname="${ln#Port \"}"
	iname="${iname%\"}"
	ovs-vsctl del-port br0 "$iname"
    done

    case "$VMROLE" in
	1)
	    ovs-vsctl add-port br0 if-v1
	    ovs-vsctl add-port br0 if-v2
	    ;;
	2)
	    ovs-vsctl add-port br0 if-v3
	    ovs-vsctl add-port br0 if-v4
	    ;;
	3)
	    ovs-vsctl add-port br0 if-v5
	    ovs-vsctl add-port br0 if-v6
	    ;;
    esac

    touch /tmp/add_itests_taps_to_switch
}

######## set_etc_wakame_vnet

deps_set_etc_wakame_vnet='
  verify_not_router
  set_global_options
  dev_git_yum_install
'

check_set_etc_wakame_vnet()
{
    [ -f /tmp/finished-set-etc-wakame-vnet ]
}

do_set_etc_wakame_vnet()
{
    stop vnet-vna
    stop vnet-vnmgr
    stop vnet-webapi
    cd /etc/openvnet
    sed -i 's/127.0.0.1/192.168.2.91/' common.conf vnmgr.conf webapi.conf
    sed -i "s/127.0.0.1/192.168.2.$(( $VMROLE + 90 ))/" vna.conf
    sed -i "s/id \"vna\"/id \"vna$VMROLE\"/" vna.conf
    touch /tmp/finished-set-etc-wakame-vnet
}


######## populate_database_for_local_test

deps_populate_database_for_local_test='
  set_global_options
  misc_initialization
  vnet_restart
'

check_populate_database_for_local_test()
{
    [ -f /tmp/finished-populate-database ]
}

do_populate_database_for_local_test()
{
    source /tmp/rubypath.sh
    cd /opt/axsh/openvnet/vnctl/bin
    (
	set -x
	## a long sleep before first one seems to be necessary
	sleep 10
	./vnctl networks add --uuid nw-vnet1 --display-name vnet1 --ipv4-network 10.1.1.0 --ipv4-prefix 24 --network-mode virtual
	set-mydpid
	./vnctl datapaths add --uuid dp-vna --display-name vna-datapath --node-id vna --dpid "0x$MYDPID"

	./vnctl interfaces add --uuid if-tap0 --mac-address 00:18:51:e5:33:66 --network-uuid nw-vnet1 --ipv4-address 10.1.1.1 --owner_datapath_uuid dp-vna --port_name if-tap0
	./vnctl interfaces add --uuid if-tap1 --mac-address 00:18:51:e5:33:67 --network-uuid nw-vnet1 --ipv4-address 10.1.1.2 --owner_datapath_uuid dp-vna --port_name if-tap1

	curl -s -X POST --data-urlencode uuid=if-dp1eth0 --data-urlencode mode=host --data-urlencode port_name=eth0 --data-urlencode mac_address=02:01:00:00:00:01 --data-urlencode owner_datapath_uuid=dp-vna --data-urlencode ipv4_address=172.16.90.10 --data-urlencode network_uuid=nw-vnet1 http://localhost:9090/api/interfaces

    	./vnctl datapaths networks add dp-vna nw-vnet1 --broadcast-mac-address 00:18:51:e5:33:01 --interface-uuid=if-dp1eth0
)
    touch /tmp/finished-populate-database
}



######## ifcfg_scripts

set-mydpid()
{
    case "$VMROLE" in
	1) MYDPID="0000aaaaaaaaaaaa" ;;
	2) MYDPID="0000bbbbbbbbbbbb" ;;
	3) MYDPID="0000cccccccccccc" ;;
	*) echo '$VMROLE not set!!!!!!' 1>&2 ;;
    esac
}

deps_ifcfg_scripts='set_global_options'

check_ifcfg_scripts()
{
    [ -f /etc/sysconfig/network-scripts/ifcfg-br0 ]
}

do_ifcfg_scripts()
{
    case "$VMROLE" in
	1) 
	    MYIP="172.16.90.10"
	    MYNETWORK="172.16.90.0"
	    MYMACADDR="02:01:00:00:00:01"
	    ;;
	2) 
	    MYIP="172.16.90.11"
	    MYNETWORK="172.16.90.0"
	    MYMACADDR="02:01:00:00:00:02"
	    ;;
	3) 
	    MYIP="172.16.91.10"
	    MYNETWORK="172.16.91.0"
	    MYMACADDR="02:01:00:00:00:03"
	    ;;
	*) echo '$VMROLE not set!!!!!!' 1>&2
    esac

    set-mydpid
    { sed "s/SETipaddr/$MYIP/" \
	| sed "s/SETdpid/$MYDPID/" \
	| sed "s/SETnetwork/$MYNETWORK/" \
	| sed "s/SETmacaddr/$MYMACADDR/" ; }  >/etc/sysconfig/network-scripts/ifcfg-br0 <<'EOF'
ONBOOT=yes
DEVICE=br0
ONBOOT=yes
DEVICETYPE=ovs
TYPE=OVSBridge
BOOTPROTO=static
IPADDR=SETipaddr
NETMASK=255.255.255.0
NETWORK=SETnetwork/24
HOTPLUG=no
OVS_EXTRA="
 set bridge     ${DEVICE} protocols=OpenFlow10,OpenFlow12,OpenFlow13 --
 set bridge     ${DEVICE} other_config:disable-in-band=true --
 set bridge     ${DEVICE} other-config:datapath-id=SETdpid --
 set bridge     ${DEVICE} other-config:hwaddr=SETmacaddr --
 set-fail-mode  ${DEVICE} standalone --
 set-controller ${DEVICE} tcp:127.0.0.1:6633
"
EOF

    # The current setup is for the eth0's of all VMs to be
    # connected to the same broadcast domain.  Same for eth1,
    # eth2, eth3, and eth4.  eth5 is user-mode NAT networking
    # to the Internet for doing yum installs, etc.

    # The current integration setup is for VM#1 & VM#2 to be
    # connected to the same physical network, but VM#3 to be
    # on a different broadcast domain.  Therefore something
    # other than eth0 needs to be used.  eth2 is used for
    # the managment interface (192.168.2.{91,92,93}).  Therefore,
    # eth3 is used for the physical network for VM#3.

    # This means that eth3 needs to be attached to the datapath,
    # which differs from the existing integration test environment.
    # Hopefully this will work.

    # Also need to change eth0 to eth3 in openvnet-testspec/dataset/base.yml
    # See code in do_testspec_install() that does this. Seems to work!

    case "$VMROLE" in
	1 | 2)
    cat >/etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
DEVICE=eth0
ONBOOT=yes
DEVICETYPE=ovs
TYPE=OVSPort
OVS_BRIDGE=br0
BOOTPROTO=none
HOTPLUG=no
EOF
	    ;;
	3)
    cat >/etc/sysconfig/network-scripts/ifcfg-eth3 <<EOF
DEVICE=eth3
ONBOOT=yes
DEVICETYPE=ovs
TYPE=OVSPort
OVS_BRIDGE=br0
BOOTPROTO=none
HOTPLUG=no
EOF
	    ;;
    esac

    case "$VMROLE" in
	1) MYCTRIP="192.168.2.91" ;;
	2) MYCTRIP="192.168.2.92" ;;
	3) MYCTRIP="192.168.2.93" ;;
	router) MYCTRIP="192.168.2.1" ;;
	*) MYCTRIP="192.168.2.99" ;;
    esac

    service NetworkManager stop
    
    ifconfig eth2 up $MYCTRIP netmask 255.255.255.0  hw ether 02:01:00:00:22:0$VMROLE
}

######## start_sbuml_vms_for_local_test

deps_start_sbuml_vms_for_local_test='
  install_sbuml_core
  set_global_options
  misc_initialization
'

reset_start_sbuml_vms_for_local_test()
{
    do-sbumlcmd "sbumlremove -all -F"
}

check_start_sbuml_vms_for_local_test()
{
    check_set_global_options || return 255
    check_install_sbuml_core || return 255
    for m in test1 test2
    do
	[ -d "$SBUMLDIR/machines/$m" ] || return 255
    done
}

do_start_sbuml_vms_for_local_test()
{
    [ -n "$centosuser" ] || exit 255
    [ -n "$SBUMLDIR" ] || exit 255
 
    do-sbumlcmd "sbumlremove -all -F"

    # The "sleep 0.3 ;" are there just so the SBUML windows will stack
    # up in the same order.
    # Changed second one to "sleep 5" to hack around bug in SBUML download code

    sleep 0.3 ; boot-login test1 10.1.1.1  00:18:51:e5:33:66 if-tap0 test1 &
    wait # apparently another bug in SBUML when quickly downloading two cloned snapshots
    # sleep 5
    boot-login test2 10.1.1.2  00:18:51:e5:33:67 if-tap1 test2 &
    wait
}


######## start_sbuml_vms_for_itests

deps_start_sbuml_vms_for_itests='
  install_sbuml_core
  set_global_options
  misc_initialization
'

reset_start_sbuml_vms_for_itests()
{
    do-sbumlcmd "sbumlremove -all -F"
}

check_start_sbuml_vms_for_itests()
{
    check_set_global_options || return 255
    check_install_sbuml_core || return 255
    case "$VMROLE" in
	1) mlist="m1 m2" ;;
	2) mlist="m3 m4" ;;
	3) mlist="m5 m6" ;;
    esac
    for m in $mlist
    do
	[ -d "$SBUMLDIR/machines/$m" ] || return 255
    done
}

do_start_sbuml_vms_for_itests()
{
    [ -n "$centosuser" ] || exit 255
    [ -n "$SBUMLDIR" ] || exit 255
 
    do-sbumlcmd "sbumlremove -all -F"

    # The "sleep 0.3 ;" are there just so the SBUML windows will stack
    # up in the same order.
    # Changed second one to "sleep 5" to hack around bug in SBUML download code
    case "$VMROLE" in
	1)
	    sleep 0.3 ; boot-login m1 10.101.0.10  02:00:00:00:00:01 if-v1 vm1 &
	    wait # apparently another bug in SBUML when quickly downloading two cloned snapshots
	    # sleep 5
	    boot-login m2 10.101.0.10  02:00:00:00:00:02 if-v2 vm2 &
	    ;;
	2)
	    sleep 0.3 ; boot-login m3 10.101.0.11  02:00:00:00:00:03 if-v3 vm3 &
	    wait # apparently another bug in SBUML when quickly downloading two cloned snapshots
	    # sleep 5
	    boot-login m4 10.101.0.11  02:00:00:00:00:04 if-v4 vm4 &
	    ;;
	3)
	    sleep 0.3 ; boot-login m5 10.101.0.12  02:00:00:00:00:05 if-v5 vm5 &
	    wait # apparently another bug in SBUML when quickly downloading two cloned snapshots
	    # sleep 5
	    boot-login m6 10.101.0.12  02:00:00:00:00:06 if-v6 vm6 &
	    ;;
    esac
    wait

    case "$VMROLE" in
	1)
	    add-eth1 m1 10.50.0.101 02:00:00:00:ff:01 if-man1
	    add-eth1 m2 10.50.0.102 02:00:00:00:ff:02 if-man2
	    ;;
	2)
	    add-eth1 m3 10.50.0.103 02:00:00:00:ff:03 if-man3
	    add-eth1 m4 10.50.0.104 02:00:00:00:ff:04 if-man4
	    ;;
	3)
	    add-eth1 m5 10.50.0.105 02:00:00:00:ff:05 if-man5
	    add-eth1 m6 10.50.0.106 02:00:00:00:ff:06 if-man6
	    ;;
    esac
}


######## install_sbuml_core

reset_install_sbuml_core()
{
    reset_start_sbuml_vms_for_local_test
    rm -fr "$SBUMLDIR"
}

check_install_sbuml_core()
{
    # select a non-root user to control SBUML
    centosuser=centoslive # the default user for the Centos live DVD
    # install in tmpfs to not use COW blocks
    SBUMLDIR="/dev/shm/sbumldemo"
    [ -d /home/$centosuser ] || return 255
    [ -d "$SBUMLDIR" ] || return 255
}

do_install_sbuml_core()
{
    cd "/dev/shm" || reportfail "cd /dev/shm"

    # next line is necessary if using SBUML's snapshot save functionality
    # yumproxy install glibc.i686 --assumeyes
    # However, it eats up a lot of the COW blocks (600MB) on the liveCD, 
    # so just copying in the few lib files needed by hand (or tar) is probably better.
    # Like this:
    tar xzvf "$SBUMLRESOURCES/libs-for-32bit-sbuml.tar.gz" -C /
    
    ## wget http://downloads.sourceforge.net/project/sbuml/core/2424-1um-1sb/sbuml-core-2424-1um-1sb-12-14-2012.tar.gz
    
    if ! [ -d "$SBUMLDIR" ]
    then
	su "$centosuser" -c "
      export DISPLAY=:0.0
      tar xzvf "$SBUMLRESOURCES/sbuml-core-2424-1um-1sb-12-14-2012.tar.gz"
      cd '$SBUMLDIR'
      mkdir -p global-data/downloads # work around SBUML bug
      ./sbumlinitdemo -c 'xterm >/dev/null 2>/dev/null &'
    "
	"$SBUMLDIR"/scripts/sbuml--install_uml_net_as_root
    fi </dev/null
    
   cat >"$SBUMLDIR"/do-sbumlcmd.sh <<EOF
#!/bin/bash
    su "$centosuser" -c "cd $SBUMLDIR; DISPLAY=:0.0 ./sbumlinitdemo -c '\$*'"
EOF
   chmod +x "$SBUMLDIR"/do-sbumlcmd.sh

   echo "$SBUMLDIR/do-sbumlcmd.sh sbumlguestexec test1 'ping 10.1.1.2 -c 2 -w 10 \>/dev/vc/1'" >/tmp/pingto2.sh
   echo "$SBUMLDIR/do-sbumlcmd.sh sbumlguestexec test2 'ping 10.1.1.1 -c 2 -w 10 \>/dev/vc/1'" >/tmp/pingto1.sh

   chmod +x /tmp/pingto{1,2}.sh
}


######## vnet_gems

deps_vnet_gems='
  misc_initialization
  vnet_from_git
'

check_vnet_gems()
{
    VNET_GEMS_RC="$(cat 2>/dev/null "$OPTS/vnet-gems-rc")"
    [ "$VNET_GEMS_RC" == 0 ] || return 255
    VNCTL_GEMS_RC="$(cat 2>/dev/null "$OPTS/vnctl-gems-rc")"
    [ "$VNCTL_GEMS_RC" == 0 ] || return 255
}

do_vnet_gems()
{
    source /tmp/rubypath.sh
    mkdir -p /opt/axsh/openvnet/vnet/.bundle
    cat >/opt/axsh/openvnet/vnet/.bundle/config <<EOF
---
BUNDLE_PATH: vendor/bundle
BUNDLE_DISABLE_SHARED_GEMS: '1'
EOF

    cd /opt/axsh/openvnet/vnet
    bundle install
    echo "$?" >"$OPTS/vnet-gems-rc"
    cd /opt/axsh/openvnet/vnctl
    bundle install
    echo "$?" >"$OPTS/vnctl-gems-rc"
}

######## vnet_from_git


deps_vnet_from_git='dev_git_yum_install'

check_vnet_from_git()
{
    [ -d /opt/axsh/openvnet/.git ]
}

do_vnet_from_git()
{
    cd /opt/axsh
    mv openvnet openvnet-hide # this should be done at the end of the rpm install
    while ! [ -d /opt/axsh/openvnet ]
    do
	if [ -d /home/centoslive/onhost/projects/openvnet/.git ]
	then
	    git clone /home/centoslive/onhost/projects/openvnet/
	else
	    git clone https://github.com/axsh/openvnet.git
	fi
    done
    mv openvnet-hide/ruby openvnet
    rm openvnet-hide -fr  # free up space
    cd openvnet
    [ "$COMMIT" != "" ] && git checkout "$COMMIT"

    (
	cd /opt/axsh/openvnet/vnet
	mkdir -p /home/centoslive/onhost/vnet-vendor
	sudo ln -s /home/centoslive/onhost/vnet-vendor vendor
    )
}


######## dev_git_yum_install

deps_dev_git_yum_install='
  set_global_options
  wakame_yum_install
'

check_dev_git_yum_install()
{
    DEV_GIT_YUM_RC="$(cat 2>/dev/null "$OPTS/dev-git-yum-rc")"
    [ -n "$DEV_GIT_YUM_RC" ] && return "$DEV_GIT_YUM_RC"
}

do_dev_git_yum_install()
{
    case "$VMROLE" in
	1 | 2 | 3)
	    yum install git gcc sqlite-devel mysql-devel --assumeyes
	    echo "$?" >"$OPTS/dev-git-yum-rc"
	    ;;
	r*) 
	    yum install git --assumeyes
	    echo "$?" >"$OPTS/dev-git-yum-rc"
	    ;;
    esac
}

######## wakame_yum_install

deps_wakame_yum_install='
  address_livedvd_issues
'

check_wakame_yum_install()
{
    WAKAME_YUM_RC="$(cat 2>/dev/null "$OPTS/wakame-yum-rc")"
    [ -n "$WAKAME_YUM_RC" ] && return "$WAKAME_YUM_RC"
}

do_wakame_yum_install()
{
    ( set -x
    
    releasever=6.4

    yum install --disablerepo=updates -y http://dlc.openvnet.axsh.jp/packages/rhel/openvswitch/${releasever}/kmod-openvswitch-2.3.0-1.el6.x86_64.rpm
    yum install --disablerepo=updates -y http://dlc.openvnet.axsh.jp/packages/rhel/openvswitch/${releasever}/openvswitch-2.3.0-1.x86_64.rpm


    #rpm -ivh http://dlc.wakame.axsh.jp.s3-website-us-east-1.amazonaws.com/epel-release
    rpm -ivh http://ftp.jaist.ac.jp/pub/Linux/Fedora/epel/6/i386/epel-release-6-8.noarch.rpm

    sudo sed -i -e 's,^#baseurl,baseurl,' -e 's,^mirrorlist=,#mirrorlist=,' -e 's,http://download.fedoraproject.org/pub/epel/,http://ftp.jaist.ac.jp/pub/Linux/Fedora/epel/,' /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel-testing.repo
    
    if true 
    then
	until curl -fsSkL -o /etc/yum.repos.d/openvnet.repo https://raw.githubusercontent.com/axsh/openvnet/master/openvnet.repo; do
	    sleep 1
	done
	until curl -fsSkL -o /etc/yum.repos.d/openvnet-third-party.repo https://raw.githubusercontent.com/axsh/openvnet/master/openvnet-third-party.repo; do
	    sleep 1
	done
    fi

    if false
    then
    curl -oL /etc/yum.repos.d/openvnet.repo -R https://raw.github.com/axsh/openvnet/master/openvnet.repo

    curl -oL /etc/yum.repos.d/openvnet-third-party.repo -R https://raw.github.com/axsh/openvnet/master/openvnet-third-party.repo
    fi

    # TODO: make proxy use optional
    #sed -i 's/mirrorlist=/#mirrorlist=/'  /etc/yum.repos.d/*
    #sed -i 's/#baseurl=/baseurl=/'  /etc/yum.repos.d/*


    # TODO: this installs stuff that is not really needed
    yum install --disablerepo=updates -y openvnet

    echo "$?" >"$OPTS/wakame-yum-rc"

    ) # end set -x
}

######## misc_initialization

check_misc_initialization()
{
    [ -f /tmp/rubypath.sh ]
}

do_misc_initialization()
{
    #pkill screensaver  # should work.  pkill screensav works.  why?
    pkill gnome-screen

    echo 'centos
centos' | passwd >/dev/null 2>/dev/null

    service NetworkManager stop  # for the mcast networking

    /etc/init.d/iptables stop  # at least so connections to ssh are not blocked
    /etc/init.d/sshd start
    
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    cat >/root/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2XeTX+9/ffKhcvSJtiTvW0sMRH3yLvOJmdm/nVAFCUr770vZPbBvh9rQ3P8+DLkt8wSieiR+n0zF5lzxFO8lxVmbEoTE2HbGklU8YvPHwwXFdKjB6A+x3ZA3SdZpDaN68d/4p9/hCvBJqMP4cGE1D6CDLkjgsJIDOV3SlnLho0SsTW906fhGD4muQlqtAD+Nq3YS+IXZ2yg2XZBxJWWAt1nK9G6cyargFRXS9hoy4eq6SoPxdb277c12vuMO9t1RB8rqfPrdA+z6ZNo5JzRssK1oQlYHtVjx1IH6YzC3tBuZMnX7AIjANoarmBVt7dizIGfHUNHM18TFLBhb0it/Q== root@livedvd.centos
EOF
    # The Centos Live DVD starts with SELINUX enabled, so this is necessary
    chcon -v --type=ssh_home_t /root/.ssh/authorized_keys

    cat >/root/.ssh/id_rsa <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEoQIBAAKCAQEAq2XeTX+9/ffKhcvSJtiTvW0sMRH3yLvOJmdm/nVAFCUr770v
ZPbBvh9rQ3P8+DLkt8wSieiR+n0zF5lzxFO8lxVmbEoTE2HbGklU8YvPHwwXFdKj
B6A+x3ZA3SdZpDaN68d/4p9/hCvBJqMP4cGE1D6CDLkjgsJIDOV3SlnLho0SsTW9
06fhGD4muQlqtAD+Nq3YS+IXZ2yg2XZBxJWWAt1nK9G6cyargFRXS9hoy4eq6SoP
xdb277c12vuMO9t1RB8rqfPrdA+z6ZNo5JzRssK1oQlYHtVjx1IH6YzC3tBuZMnX
7AIjANoarmBVt7dizIGfHUNHM18TFLBhb0it/QIBIwKCAQBOWnRAr2zL3v1+/hbt
L86CewzjO2n1XSsKPeXwqqDzRDFXpvEYNknwg2Q8F8QZsN2V2aITKH0/Ty1MnevH
dryc1pU40WfOWJ6s7lK3kF6vG3hEfYxbQfDQNg8GA1wtz8vZf8Vu6dPkpkmrQzp1
1M8B8LB62Eq/bsHaAn+s9dliE9tPtP+gzv/wE3JWUj6pf/v5SagsqeJFXyusclWU
vRodOX2pH+jerysE7p3cLq3sKba7fjYCedhABOpomOl+6NDU9SmdNx66voOq/FVS
pWgurZGEHadZxBdzz9CQDr/ikJmecDDCknU7OE24djOMzGbOUBDFwy83nyal4TsL
CSGLAoGBANK/aeSUNkmU0Jx+4o2kOQKu69upkMwmU61jF4J0nKH76W2CNU5c+gnN
KQJpRz2w5Hg2EELUPUuUsQYkvxzlc/tRmmAf69jx7TOGSwCPXm5KtDXok7wZwqdb
PTVUTHzR/Ynq3S4VxyOv1SAhtOhGo/BGN+/NLemRrhSDM3DVymrFAoGBANAzb+oP
rMemQwAdUvP9AARWcNzAnaxJWMPtJKQam0rnBjbHpp6vDXOYYVuQ6w6mB/L49bbM
LyJO+27xbfCQyjEgrICCH39JocBdQG2wdI+B8tFndL3wtckevjpaIAJNNpRvVz8s
mp7fedCJKNytFFGi+oqfemZYBNoGoD9xWknZAoGBAKKTqXXRa7UbB1QnXlACV91/
oAE5qjcWQI0R7ZCF1+qsY52e9ev+lQA/LkOwTOZyhFy7/eppNplkE4hlfXyxAbM+
8265ig3B8X+E2sXq8RNA8WtqRhTDakaW13JIWEMIZIBWGFbAV8sSnRjJi46c5N3t
BpRrFMof7LC8+8wSo3bvAoGAC+Wun6kf0OTt4r/Y2r4AAD90Kd8e8+bvISN+b8cB
j0BmwU08uJxJ6VkqIn1PQqpm2q8j+9EnQ8n/vTJeDb8hfyZwQduMxXHr/F0Zn94y
i9uKN9oGq8ScrGgoIJdvixpa4+ka7arHAcOgj5LPIo2MIewOURBtZO8WOFgmagZ6
MBsCgYA1CXzxPbLNOWZP8769J/fHfMgztdFLGSoU5MH409fT/sPMGBpY41vqlV3/
+oy6qlfU4TJV6XcUZOvSljC5lZZ25rpq/Q2LocXJDLD9ldd+72zQ3tK35nEaaVox
CgbdrbxJlZM9aXMQRvKxE2QXzw2HFyXTxQjtHiuiM+axxUZu7w==
-----END RSA PRIVATE KEY-----
EOF
    chmod 600 /root/.ssh/id_rsa

    # pack up ssh keys for copying into SBUML VMs via hostfs
    ( cd /root &&  tar czvf /tmp/ssh.tar.gz .ssh )

    # make shortcut for debugging ssh logins to set path
    echo 'PATH=/opt/axsh/openvnet/ruby/bin:$PATH' >/tmp/rubypath.sh
    source /tmp/rubypath.sh
    # rspec scripts want ruby all setup when giving command via ssh to root
    grep ruby /root/.bash_profile || cat /tmp/rubypath.sh >> /root/.bashrc

    # another shortcut for vnflows-monitor
    echo 'PATH=/opt/axsh/openvnet/ruby/bin:$PATH ; /opt/axsh/openvnet/vnet/bin/vnflows-monitor "$@"' >/tmp/dump.sh

    # quick fix for problem with virtual box sometimes not setting up DNS
    # start inside a subprocess so that "wait" below will not wait for this
    ( while sleep 1.1 ; do echo nameserver 8.8.8.8 >/etc/resolv.conf ; done 1>/dev/null 2>&1 0<&1  & )
    sleep 2
}

######## address_livedvd_issues

check_address_livedvd_issues()
{
    [[ "$(dmsetup status)" == *live* ]] || return 0
    mount | grep '^/tmp/opt ' 1>/dev/null && [ "$(getenforce)" != "Enforcing" ]
}

do_address_livedvd_issues()
{
    if [[ "$(dmsetup status)" == *live* ]]
    then
        # turn off selinux!!
	setenforce 0

	# move /var and /opt from livedvd snapshot device to tmpfs device
	cp -a /var /tmp
	cp -a /opt /tmp
	mount /tmp/opt /opt -o bind
	# beware...this makes strange output appear in "df
	# -h"..something about sunrpc??
	mount /tmp/var /var -o bind
	(
	    cd /var/cache/
	    rm -fr yum
	    mkdir -p /home/centoslive/onhost/var-cache-yum
	    sudo ln -s /home/centoslive/onhost/var-cache-yum yum
	    sed -i 's/keepcache=0/keepcache=1/' /etc/yum.conf
	)
    fi
}

######## set_global_options

OPTS=~/vnet-test-options
mkdir -p "$OPTS"

reset_set_global_options()
{
    rm "$OPTS"/*
}

check_set_global_options()
{
    [ "$CODESOURCE" = "" ] && CODESOURCE="$(cat 2>/dev/null "$OPTS/gitorrpm")"
    case "$CODESOURCE" in
	git | rpm) : ;;
	*) CODESOURCE="" ;;
    esac
    [ "$VMROLE" = "" ] && VMROLE="$(cat 2>/dev/null "$OPTS/vmrole")"
    case "$VMROLE" in
	1 | 2 | 3 | r*) : ;;
	*) VMROLE="" ;;
    esac

    [ "$COMMIT" = "" ] && COMMIT="$(cat 2>/dev/null "$OPTS/commit")"

    # Default to these values (mainly when using vm*/vnetscript-shortcut.sh)
    echo "$CODESOURCE" >"$OPTS/gitorrpm"
    echo "$VMROLE" >"$OPTS/vmrole"
    [ "$CODESOURCE" != "" ] && [ "$VMROLE" != "" ] && return 0
    return 255
}

do_set_global_options()
{
    if [ "$CODESOURCE" = "" ]
    then
	echo "Enter where to get vnet source from: git or rpm"
	read_or_param ; CODESOURCE="$val"
	echo "$CODESOURCE" >"$OPTS/gitorrpm"
    fi
    if [ "$VMROLE" = "" ]
    then
	echo "Enter which virtual machine this is in the integration test setup: 1, 2, 3, or r"
	read_or_param ; VMROLE="$val"
	echo "$VMROLE" >"$OPTS/vmrole"
    fi

    if [ "$COMMIT" = "" ]
    then
	echo "Enter sha1 hash for commit"
	read_or_param ; COMMIT="$val"
	echo "$COMMIT" >"$OPTS/commit"
    fi
}

# {do/check/do1/check1/reset1} {list of steps....} -- params
main()
{
    try abspath="$(cd $(dirname "$0") ; pwd )"
    try cd "$abspath"

    case "$1" in
	check | check1 | 'do' | do1 | reset1)
	    cmd="$1"
	    shift
	    ;;
	*)
	    cmd=check
	    ;;
    esac

    # split remaining params into those before "--" and those after (if any).
    steplist=() # installation/demo steps to process
    while [ "$#" != 0 ]
    do
	p="$1" ; shift
	[ "$p" = "--" ] && break
	func_defined "check_$p" || return
	func_defined "do_$p" || return
	steplist=( "${steplist[@]}" "$p" )
    done
    paramlist=() # params taken one by one by interactive prompts, for one-line shortcuts
    while [ "$#" != 0 ]
    do
	p="$1" ; shift
	paramlist=( "${paramlist[@]}" "$p" )
    done

    [ "${#steplist[@]}" = 0 ] && steplist=( $default_steps )

    for step in "${steplist[@]}"
    do
	echo
	echo "=================  ${cmd}_cmd" "$step"
	"${cmd}_cmd" "$step"
    done
}

read_or_param()
{
    if [ "${#paramlist[@]}" = 0 ]
    then
	read val
    else
	val="${paramlist[0]}"
	paramlist=("${paramlist[@]:1}") # shift array
	echo "(from cmdline): $val"
    fi
}

func_defined()
{
    if ! declare -f "$1" > /dev/null  # function defined?
    then
	echo "Function for step not found: $1" 1>&2
	return 1
    fi
    return 0
}

check1_cmd()
{
    try cd "$abspath"
    local stepname="$1"
    local indent="$2"

    printf "*%-10s %s   " "${indent//  --  /*}" "$indent$stepname"
    if "check_$stepname"
    then
	echo "Done (maybe)"
    else
	echo "Not Done"
    fi
}

already_checked=""
: ${dedup:=yes}
: ${dotout:=/tmp/vnet.dot}
check_cmd()
{
    local stepname="$1"
    local indent="$2"
    local dotlevel="$dotlevel"
    local depstep

    if [ "$dotout" != "" ]; then
	if [ "$dotlevel" = "" ]; then
	    exec 44>"$dotout"
	    echo "strict digraph { " >&44
	    dotlevel=1
	else
	    dotlevel=$(( dotlevel + 1 ))
	fi
    fi

    check1_cmd "$stepname" "$indent"
    if [ "$dedup" = "yes" ]; then
	tmp="${already_checked//$stepname/}"
	[[ "$tmp" == *,,* ]] && return
	already_checked="$already_checked ,$stepname, "
    fi

    # uncomment to have the step source inserted in output
    # eval type "do_${stepname}"

    local deps
    eval 'deps=$deps_'"$stepname"
    for depstep in $deps
    do
	check_cmd "$depstep" "$indent  --  "
	[ "$dotout" = "" ] && continue
	echo "$depstep -> $stepname" >&44
    done

    if [ "$dotout" != "" ] && [ "$dotlevel" = "1" ]; then
	echo "}" >&44
    else
	dotlevel=$(( dotlevel - 1 ))
    fi
}

reset1_cmd()
{
    local stepname="$1"
    local indent="$2"
    echo -n "$indent$stepname   "
    if "reset_$stepname"
    then
	echo "Maybe reset."
    else
	echo "Probably did not reset."
	exit 255
    fi
}

do1_cmd()
{
    try cd "$abspath"
    local stepname="$1"
    local indent="$2"
    echo -n "$indent$stepname   "
    if "do_$stepname"
    then
	if "check_$stepname"
	then
	    echo "Success."
	else
	    echo "Ran but failed check....exiting."
	    exit 255
	fi
    else
	echo "Failed....exiting." 1>&2
	exit 255
    fi
}

do_cmd()
{
    local stepname="$1"
    local indent="$2"

    if "check_$stepname" 
    then
	echo "$indent$stepname :: Probably already done"
	return 0
    fi

    local deps
    eval 'deps=$deps_'"$stepname"
    for depstep in $deps
    do
	do_cmd "$depstep" "$indent  --  "
    done

    do1_cmd "$stepname" "$indent"
}

wait-and-rename-tap()
{
    # wait for a line like this:
    # bash -c echo 1 > /proc/sys/net/ipv4/conf/tap0/proxy_arp

    sbuml-expect "$VM" '*proxy_arp*' 4
    sso="$(sbumlstdout "$VM")"
    gettap="$(tail -n "$lookback" "$sso")"
    # make sure we don't find it next time
    echo $'\n\n\n\n' >>"$sso"

    gettap="${gettap%/proxy_arp*}"
    gettap="${gettap##*/}"  # now it should be something like "tap0"
    rename-tap "$gettap" "$TAP"
}

add-eth1()
{
    VM="$1"
    add-eth1-for-rh80 "$@"
}

add-eth1-for-rh80()
{
    VM="$1"
    IP="$2"
    MAC="$3"
    TAP="$4"

    # grab parameter for tap from previous command line of already launched SBUML
    tapinfo="$(ps aux | grep -m 1 -o 'tuntap,,,[^ ]* ')" # something like: tuntap,,,10.0.3.15
    do-sbumlcmd "sbumlmconsole $VM config eth1=$tapinfo"

    trycount=15
    while sleep 1.23 && (( trycount-- )) ; do
	do-sbumlcmd "sbumlguestexec $VM ifconfig eth1 up $IP netmask 255.255.255.0 hw ether $MAC"
	r="$(do-sbumlcmd "sbumlguestexec $VM ifconfig eth1")"
	[[ "$r" == *UP* ]] && break
    done

    wait-and-rename-tap
    # celebrate:

    #do-sbumlcmd "sbumlguestexec $VM route add default eth1"
    # The next line works, but not sure if we can know for sure that
    # ssh connections from the host VM will always look like they
    # come from 10.0.2.15.  TODO: check closer
    do-sbumlcmd "sbumlguestexec $VM route add -net 10.0.2.0 netmask 255.255.255.0 dev eth1"
    
    do-sbumlcmd "sbumlguestexec $VM ifconfig eth0 \>/dev/vc/1"
    do-sbumlcmd "sbumlguestexec $VM ifconfig eth1 \>/dev/vc/1"

    route add -host "$IP" dev "$TAP"
}

boot-login()
{
    restore-prebooted-rh80vm "$@"
}

restore-prebooted-rh80vm()
{
    VM="$1"
    IP="$2"
    MAC="$3"
    TAP="$4"
    HOSTNAME="$5"

    [ -d "$SBUMLDIR"/machines/$VM ] && return
    # 67880b/ has restarted sshd to get rid of old DNS
    # SNAPSHOT=rh80b-v004-dhcp-config-for-eth0-optional-debugging-e98a8df18164d087
    # SNAPSHOT=rh80b-v005-new-ssh-client-9f37bb3885c1f901
    # SNAPSHOT=rh80b-v008-fetched-in-ssh-7e3c90d59668dd4b
    # SNAPSHOT=rh80b-v008-fetchedin-ssh-ping-etc-e4ec6c12ecc9ff34
    # SNAPSHOT=rh80b-v009-recent-netcat-from-centos-092ab975f5ce39c4
    SNAPSHOT=rh80b-v010-move-nc-to-slash-bin-c4e5ba795eedf50b
    do-sbumlcmd "sbumlrestore $VM $SNAPSHOT -c -sd $SBUMLRESOURCES/"
    # no need to login :-)

    # this removes a default UML specific script that overides too much.
    # Taking this out because current snapshot (f1e6f2) has the standard
    # ifcfg-eth0 for DHCP.
    #do-sbumlcmd "sbumlguestexec $VM rm -f /etc/sysconfig/network-scripts/ifcfg-eth0"

    # removing resolv.conf stops the VM from wasting time (and overruning timeouts) by
    # trying to use an out-of-date server (at Todai!).
    do-sbumlcmd "sbumlguestexec $VM rm -f /etc/resolv.conf"

    do-sbumlcmd "sbumlguestexec $VM hostname $HOSTNAME"
    do-sbumlcmd "sbumlguestexec $VM tar xzvf /h/tmp/ssh.tar.gz -C /root"
    do-sbumlcmd "sbumlguestexec $VM ifconfig eth0 up $IP netmask 255.255.255.0 hw ether $MAC"
    wait-and-rename-tap

    # and yet another workaround.  ifup and ifdown remove the tap devices on the host, so
    # disable for now.
    # Not disabling now...because the current snapshot (f1e6f2) disables
    # calls from ifdown to "if link $dev down"
    #do-sbumlcmd "sbumlguestexec $VM mv /sbin/ifup /sbin/ifup-hide"
    #do-sbumlcmd "sbumlguestexec $VM mv /sbin/ifdown /sbin/ifdown-hide"
}

rename-tap()
{
    ifconfig "$1" down || return
    ip link set "$1" name "$2"
    ifconfig "$2" up
}

do-sbumlcmd()
{
    check_install_sbuml_core || reportfail "SBUML is not installed"
    su "$centosuser" -c "cd $SBUMLDIR; DISPLAY=:0.0 ./sbumlinitdemo -c '$*'"
}

sbumlstdout()
{
    VM="$1"
    echo "$SBUMLDIR/machines/$VM/stdout"
}

sbuml-expect()
{
    VM="$1"
    PAT="$2"
    lookback="$3"
    sso="$(sbumlstdout "$VM")"
    trycount=30
    while ! [ -f "$sso" ] ; do
	sleep 1
	(( trycount-- )) || return 255
    done
    while [[ "$(tail -n "$lookback" "$sso")" != $PAT ]] ; do
	[ -f "$sso" ] || return 255 # VM was removed
	sleep 0.2
	sso="$(sbumlstdout "$VM")"
    done
    return 0
}




cat >/tmp/utils.sh <<'EOFlong'
util-remove-test-ports()
{
    ovs-vsctl del-port br0 if-tap0
    ovs-vsctl del-port br0 if-tap1
    ovs-vsctl show
}

util-add-ports-for-rspec()
{
    ( 
	set -x
	for i in $(ifconfig | grep -o 'if-v[0-9]')
	do
	    ovs-vsctl add-port br0 $i
	done
	ovs-vsctl show
    )
}

util-cmd-in-all-vms()
{
    for i in 91 92 93
    do
	ssh root@192.168.2.$i "$*"
    done
}

util-from-router-set-all-etc-wakame-vnet()
{
    for i in 91 92 93
    do
	ssh root@192.168.2.$i <<EOF
stop vnet-vna
stop vnet-vnmgr
stop vnet-webapi
cd /etc/openvnet
sed -i 's/127.0.0.1/192.168.2.91/' common.conf vnmgr.conf webapi.conf
sed -i 's/127.0.0.1/192.168.2.$i/' vna.conf
sed -i 's/id "vna"/id "vna${i#9}"/' vna.conf
EOF
    done
}

util-from-router-set-all-taps()
{
    for i in 91 92 93
    do
	ssh root@192.168.2.$i "$(cat /tmp/utils.sh) ; util-remove-test-ports ; util-add-ports-for-rspec "
    done
}

util-from-router-set-br0-macaddr() # is this necessary?
{
    for i in 91 92 93
    do
	echo "doing: $i"
	ssh root@192.168.2.$i "ifconfig br0 | grep HW ; ifconfig br0 hw ether 02:01:00:00:00:0${i#9}"
    done
}

util-continuious-set-br0-macaddr()
{
    while sleep 2
    do
	util-from-router-set-br0-macaddr
    done
}

util-from-router-do-all()
{
    util-from-router-set-all-taps
    util-from-router-set-all-etc-wakame-vnet
    util-from-router-set-br0-macaddr
}

EOFlong




echo $$ >>/tmp/test-vnet-pids
cat >/tmp/test-vnet-killall.sh <<'EOF'
for i in $(cat /tmp/test-vnet-pids)
do
  kill $i
done
EOF

main "$@"

pids="$(cat /tmp/test-vnet-pids)"
echo "$pids" | grep -v "$$" >/tmp/test-vnet-pids
