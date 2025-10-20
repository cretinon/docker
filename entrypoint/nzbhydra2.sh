#!/bin/sh

force_route() {
    route del default

    VPN=$(cat $vpn)
    route add default gw $VPN

    NET=$(cat $route)
    GW=$(cat $gw)
    ip route add to $NET via $GW dev eth0 onlink

}

dir="/nzbhydra2"
route="$dir/.route"
gw="$dir/.gw"
vpn="$dir/.vpn"

force_route

/opt/Nzbhydra2/nzbhydra2wrapperPy3.py --datafolder /nzbhydra2


