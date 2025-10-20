#!/bin/sh

USER=$(cat /run/secrets/username)
PASS=$(cat /run/secrets/password)
DNS=$(cat /run/secrets/dns)

__token=$(echo -n $USER:$PASS | base64)
__dns=$DNS

while [ 1 ]; do
  date
  curl -s -H 'Authorization: Basic '$__token "https://nic.ChangeIP.com/nic/update?&hostname='$__dns'&set=1" 
  echo
  sleep 300
done
