#!/bin/bash

mkdir -p /mnt/nfs
mkdir -p "/etc/auto.master.d/"
echo "/mnt/nfs        /sonarr/auto.mntnfs --ghost,--timeout=60" > /etc/auto.master.d/mntnfs.autofs

/etc/init.d/autofs restart

/opt/Sonarr/Sonarr --data=/sonarr/config
