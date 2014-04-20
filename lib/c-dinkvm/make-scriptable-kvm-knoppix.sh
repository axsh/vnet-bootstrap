#!/bin/bash

# Tested OK with knoppix v7.0.4, v6.7.1
# For v6.2.1, the parameters for a netcat server is "nc -l -p port", so needs minor modification to work
# ...but now using busybox; have not tested on v6.2.1 yet.

kiso="$1" # path to knoppix ISO

if [ "$2" = "" ]
then
    targetdir="$(pwd)/scriptable-knoppix-setup"
else
    targetdir="${2%/}"
fi


set -e  # stop on any error

dofail()
{
    echo "Failed...exiting. ($@)" 1>&2
    exit 255
}

[ -f "$kiso" ] || dofail "Not found: $kiso"
[ "$(whoami)" = "root" ] || dofail "Must run as root"
[ -d "$targetdir" ] && dofail "$targetdir already exists"
[ -f make-scriptable-kvm-knoppix.sh ] && [ -f busybox ] || dofail "must run from same dir as this script and busybox"

bbpath="$(pwd)"

mkdir "$targetdir"

# (1) extract linux, conf, and minirt.gz

mkdir "$targetdir/miso"

mount "$kiso" "$targetdir/miso" -o loop,ro

cp "$targetdir/miso/isolinux/vmlinuz0" "$targetdir"
cp "$targetdir/miso/isolinux/isolinux.cfg" "$targetdir"
cp "$targetdir/miso/isolinux/initrd0.img" "$targetdir"

sleep 5

umount "$targetdir/miso" || { sleep 3 && umount "$targetdir/miso" ; }
rmdir "$targetdir/miso"

# (2) expand minirt

mkdir "$targetdir/expanded"

(
    cd "$targetdir/expanded"
    cat ../initrd0.img | gunzip -c |  cpio -imd --no-absolute-filenames 2>/dev/null

)

# (3) modify init

(
    cd "$targetdir/expanded"

#    ls -l init
    execLine="$(grep -n 'Switching root' init | tail -n 1)"
    execLine="${execLine%%:*}"
    totLines="$(cat init | wc -l)"
    
    cp -a init init.org
    
    # FIRST PART
    head -n $(( execLine - 2 )) init.org  >init
#    ls -l init

    # NEW PART
    cat >>init <<'EOF'
## extra lines for minirt/init start

cat >/sysroot/bin/simple-guest-bash-server.sh <<'EOF3'
#!/bin/bash

prefixitin()
{
   prefix="$1"
   IFS=""
   while read -r ln 
   do
     echo "$prefix$ln" 1>"$xtermtty"  # send to xterm in KVM
     [ "$ln" == "xxEOFxx" ] && exit
     echo "$ln"
   done
}

prefixitout()
{
   prefix="$1"
   IFS=""
   while read -r ln 
   do
     echo "$prefix$ln" 1>"$xtermtty"  # send to xterm in KVM
     echo "$ln" >&99 # send to host
   done
}

prefixiterr()
{
   prefix="$1"
   IFS=""
   while read -r ln 
   do
     echo "$prefix$ln" 1>"$xtermtty"  # send to xterm in KVM
     echo "$prefix$ln" >&99 # send to host
   done
}

closefds()
{
   # needed because for the redirection of stdout and stderr, the
   # original file descriptors are created at e.g. 62 and 63 and
   # copied to 1 and 2.  Created background processes will get these
   # too, and then bash will refuse to exit with its stderr and stdout
   # still open in other processes.
   for (( i=3 ; i<100 ; i++ ))
   do
      eval "exec $i<&-"
   done
}
export -f closefds

exec 99>&1
( echo "closefds" ;  prefixitin ' in: ' ) | bash 1> >(prefixitout 'out: ') 2> >(prefixiterr 'ERR: ')
EOF3

/from-knoppix704/busybox chmod +x /sysroot/bin/simple-guest-bash-server.sh

cat >/sysroot/bin/start-simple-guest-bash-server.sh <<'EOF4'
bash -c "sleep 5 ; xterm -e bash -c 'top;bash' & xterm -e bash -c '
  sudo /etc/init.d/iptables stop ;
  which sshfs || sudo rpm -iv /dev/shm/fuse-sshfs-2.4-1.el6.x86_64.rpm ;
  pkill screensaver ;
  export xtermtty=\$(tty) ;
  /bin/from-knoppix704/busybox nc -ll -p 11222 -e /bin/simple-guest-bash-server.sh ; bash'"
EOF4

/from-knoppix704/busybox chmod +x /sysroot/bin/start-simple-guest-bash-server.sh


#/home/centoslive/.config/autostart/start-simple-guest-bash-server.sh.desktop

cat >>/sysroot/etc/rc.local <<EOF6
mkdir -p /home/centoslive/.config/autostart/
cp /dev/shm/start-simple-guest-bash-server.sh.desktop /home/centoslive/.config/autostart/start-simple-guest-bash-server.sh.desktop
EOF6

cat >/dev/shm/start-simple-guest-bash-server.sh.desktop <<EOF5

[Desktop Entry]
Type=Application
Exec=/bin/start-simple-guest-bash-server.sh
Hidden=false
X-GNOME-Autostart-enabled=true
Name[en_US]=script server
Name=script server
Comment[en_US]=
Comment=
EOF5

cp -r /from-knoppix704 /sysroot/bin
cp fuse-sshfs-2.4-1.el6.x86_64.rpm /dev/shm

## extra lines for minirt/init end
EOF

    # THE REST
    tail -n $(( totLines - execLine + 2 )) init.org >>init

    # diff init.org init || true
    
    # copy out for debugging
    cp init init.org ../

    # copy in busybox from knoppix 7.0.4 DVD
    mkdir from-knoppix704
    cp "$bbpath"/busybox "$bbpath"/busybox.sha1 from-knoppix704
    cp "$bbpath"/fuse-sshfs-2.4-1.el6.x86_64.rpm .

    # double number of snapshot blocks for Live DVD to increase time until eventual crash
    sed -i 's/512\*1024/512\*1024\*2/' ./sbin/dmsquash-live-root
)


# (4) repack minirt.gz

(
    cd "$targetdir"
    # will rename from initrd0.img to minirt.gz ,,,, mv minirt.gz minirt.gz.org

    cd expanded
    find . | cpio -oH newc 2>/dev/null | gzip -9 > ../minirt.gz

    ## go ahead and get rid of expanded/
    cd ..
    rm -fr expanded
    # chmod 777 -R expanded
)

# (5) make soft link to iso file

ln -s "$kiso" "$targetdir/link-to-knoppix.iso"
echo "${kiso##*/}" >"$targetdir/iso-filename.txt"

# (6) output startup script

# original line from syslinux.cfg in CentOS-6.4-x86_64-LiveDVD.iso
kcmdline="initrd=initrd0.img root=live:CDLABEL=CentOS-6.4-x86_64-LiveDVD rootfstype=auto ro liveimg quiet nodiskmount nolvmmount  rhgb vga=791 rd.luks=0 rd.md=0 rd.dm=0"

cat >"$targetdir/start-scriptable-kvm.sh" <<EOF
set -x
reportfail()
{
    echo "Failed (\$*). Exiting." 1>&2
    exit 255
}
export SCRIPT_DIR="\$(cd "\$(dirname "\$(readlink -f "\$0")")" && pwd -P)" || reportfail  # use -P to get expanded absolute path

# All options are set with environment variables.  Set to " " (one space) to disable.

# (1) Knoppix ISO file
theiso=""
orgloc="\$(readlink -f "\$SCRIPT_DIR/link-to-knoppix.iso")" # link gets preference
[ -f "\$orgloc" ] && theiso="\$orgloc"
[ "\$theiso" != "" ] || theiso="\$KVMISO" # set by dinkvm script
[ "\$theiso" != "" ] || reportfail "could not locate knoppix iso file"

# (2) forwarded ports
[ "\$bashHPORT" = "" ] && bashHPORT="10199"
[ "\$sshHPORT" = "" ] && sshHPORT="10122"
[ "\$httpHPORT" = "" ] && httpHPORT="10180"
[ "\$monHPORT" = "" ] && monHPORT="10197"

portforward="hostfwd=tcp:127.0.0.1:\$bashHPORT-:11222"
portforward="hostfwd=tcp:127.0.0.1:\$sshHPORT-:22,\$portforward"
portforward="hostfwd=tcp:127.0.0.1:\$httpHPORT-:80,\$portforward"

# (3) user mode network
[ "\$usernet" = "" ] && usernet="-net nic,vlan=0,model=virtio -net user,vlan=0,\$portforward"

# (4) mcast network
[ "\$mcastADDR" = "" ] && mcastADDR="230.0.0.1"
[ "\$mcastPORT" = "" ] && mcastPORT="1234"
[ "\$mcastMAC" = "" ] && mcastMAC="52:54:00:12:00"  # must add the 6th part below

mcastnet1="-net nic,vlan=1,macaddr=\$mcastMAC:01  -net socket,vlan=1,mcast=\$mcastADDR:\${mcastPORT}1"
mcastnet2="-net nic,vlan=2,macaddr=\$mcastMAC:02  -net socket,vlan=2,mcast=\$mcastADDR:\${mcastPORT}2"
mcastnet3="-net nic,vlan=3,macaddr=\$mcastMAC:03  -net socket,vlan=3,mcast=\$mcastADDR:\${mcastPORT}3"
mcastnet4="-net nic,vlan=4,macaddr=\$mcastMAC:04  -net socket,vlan=4,mcast=\$mcastADDR:\${mcastPORT}4"
mcastnet5="-net nic,vlan=5,macaddr=\$mcastMAC:05  -net socket,vlan=5,mcast=\$mcastADDR:\${mcastPORT}5"
# mcast

# (5) memory
[ "\$kvmMEM" = "" ] && kvmMEM="-m 1024"

# (6) kvm display
[ "\$kvmDISP" = "" ] && kvmDISP=" " # use default (-sdl)

# (7) kvm vga card
[ "\$kvmVGA" = "" ] && kvmVGA="-vga vmware"

# (8) kvmMISC
[ "\$kvmMISC" = "" ] && kvmMISC=" "

# (1-8) put it together
[ "\$kvmparams" = "" ] && kvmparams="-cdrom \$theiso \$usernet \$mcastnet1 \$mcastnet2 \$mcastnet3 \$mcastnet4 \$mcastnet5 \$kvmMEM \$kvmDISP \$kvmVGA \$kvmMISC"

[ "\$KVMBIN" = "" ] && KVMBIN="kvm"
[ "\$KVMKERNEL" = "" ] && KVMKERNEL="./vmlinuz0"

# (9) linux kernel command line
kcmdline="$kcmdline"
# remove old minirt.gz parameter, because it will be loaded directly by KVM
kcmdline="\${kcmdline/initrd=minirt.gz /}"
kcmdline="\${kcmdline} \$kcmdlineMISC" # add extras from calling script

cd "\$SCRIPT_DIR"
# the eval is used because the quotes in $kvmparams need to be parsed
eval thewholething=( \$KVMBIN \$kvmparams -monitor telnet::\$monHPORT,server,nowait -kernel \$KVMKERNEL -initrd "./minirt.gz" )
# but don't eval here so kcmdline does not go through word splitting
thewholething=( "\${thewholething[@]}" -append "\$kcmdline" )

# make first line of kvm.out be the something that can be evaled to recreate thewholething array
declare -p thewholething

exec "\${thewholething[@]}"
EOF
chmod +x "$targetdir/start-scriptable-kvm.sh"
