#!/bin/sh

dir="/sonarr"

mkdir -p /mnt/nfs

cat <<EOF > $dir/auto.syno
Films        -fstype=nfs,rw   192.168.2.36:/volume1/Films
Download     -fstype=nfs,rw   192.168.2.36:/volume1/Download
EOF

/etc/init.d/autofs restart

/opt/Sonarr/Sonarr --data=/sonarr/config


