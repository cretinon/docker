#!/bin/sh

force_route() {
    route del default

    VPN=$(cat $vpn)
    route add default gw "$VPN"

    NET=$(cat $route)
    GW=$(cat $gw)
    ip route add to "$NET" via "$GW" dev eth0 onlink

}

dir="/sabnzbd"
route="$dir/.route"
gw="$dir/.gw"
vpn="$dir/.vpn"

force_route

mkdir -p /mnt/nfs

cat <<EOF > $dir/auto.syno
Download     -fstype=nfs,rw   192.168.2.36:/volume1/Download
EOF

/etc/init.d/autofs restart

/usr/bin/sabnzbdplus -s 0.0.0.0 -f /sabnzbd/
