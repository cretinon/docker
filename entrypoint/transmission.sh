#!/bin/bash

# shellcheck source=/dev/null

cont_name="/transmission"

source "$cont_name/$cont_name.conf"
source "/mini_lib.sh"

force_route() {
    route del default
    route add default gw "$1"
    ip route add to "$2" via "$3" dev eth0 onlink
}

add_nfs () {
    mkdir -p /mnt/nfs
    echo "/mnt/nfs        /transmission/auto.syno --ghost,--timeout=60" > /etc/auto.master.d/syno.autofs
    echo "$NFS" > $cont_name/auto.syno
    Download     -fstype=nfs,rw   192.168.2.36:/volume1/Download
    /etc/init.d/autofs restart
}

force_route "$VPN" "$NET" "$GW"
add_nfs "$cont_name" "$NFS"

/usr/bin/transmission-daemon --foreground --config-dir /etc/transmission-daemon/ --log-debug
