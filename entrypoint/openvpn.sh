#!/bin/bash

set -o nounset                              # Treat unset variables as an error

### firewall: firewall all output not DNS/VPN that's not over the VPN connection
# Arguments:
#   none)
# Return: configured firewall
firewall() {

    local port="${1:-1194}" docker_network="$(ip -o addr show dev eth0| awk '$3 == "inet" {print $4}')" 

    sysctl net.ipv4.ip_forward
	     
    [[ -z "${1:-""}" && -r $conf ]] && port="$(awk '/^remote / && NF ~ /^[0-9]*$/ {print $NF}' $conf | grep ^ || echo 1194)"

    iptables -F OUTPUT
    iptables -P OUTPUT DROP
    iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A OUTPUT -o tap0 -j ACCEPT
    iptables -A OUTPUT -o tun0 -j ACCEPT
    iptables -A OUTPUT -d ${docker_network} -j ACCEPT
    iptables -A OUTPUT -p udp -m udp --dport 53 -j ACCEPT
    iptables -A OUTPUT -p tcp -m owner --gid-owner vpn -j ACCEPT 2>/dev/null &&
    iptables -A OUTPUT -p udp -m owner --gid-owner vpn -j ACCEPT || {
        iptables -A OUTPUT -p tcp -m tcp --dport $port -j ACCEPT
        iptables -A OUTPUT -p udp -m udp --dport $port -j ACCEPT; }

    iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
    
    [[ -s $route ]] && for net in $(cat $route); do return_route $net; done
}

### return_route: add a route back to your network, so that return traffic works
# Arguments:
#   network) a CIDR specified network range
# Return: configured return route
return_route() {
    local network="$1" gw="$(ip route |awk '/default/ {print $3}')"

    ip route | grep -q "$network" || ip route add to $network via $gw dev eth0 onlink
    iptables -A OUTPUT --destination $network -j ACCEPT
}

dir="/vpn"
auth="$dir/vpn.cert_auth"
conf="$dir/vpn.conf"
cert="$dir/vpn-ca.crt"
route="$dir/.firewall"

[[ -f $conf ]] || { [[ $(ls $dir/*|egrep '\.(conf|ovpn)$' 2>&-|wc -w) -eq 1 ]]&& conf="$(ls $dir/* | egrep '\.(conf|ovpn)$' 2>&-)"; }
[[ -f $cert ]] || { [[ $(ls $dir/* | egrep '\.ce?rt$' 2>&- | wc -w) -eq 1 ]] && cert="$(ls $dir/* | egrep '\.ce?rt$' 2>&-)"; }

if ps -ef | egrep -v 'grep|openvpn.sh' | grep -q openvpn; then
    echo "Service already running, please restart container to apply changes"
else
    mkdir -p /dev/net
    [[ -c /dev/net/tun ]] || mknod -m 0666 /dev/net/tun c 10 200
    [[ -e $conf ]] || { echo "ERROR: VPN not configured!"; sleep 120; }
    [[ -e $cert ]] || grep -q '<ca>' $conf || { echo "ERROR: VPN CA cert missing!"; sleep 120; }

    firewall
    exec sg vpn -c "openvpn --cd $dir --config $conf"
fi
