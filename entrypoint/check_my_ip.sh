#!/bin/bash

USER=$(cat /run/secrets/username)
PASS=$(cat /run/secrets/password)
DNS=$(cat /run/secrets/dns)

__token=$(echo -n "$USER:$PASS" | base64)
__dns=$DNS

while true ; do
  date
  curl -s -H 'Authorization: Basic '"$__token" "https://nic.ChangeIP.com/nic/update?&hostname='$__dns'&set=1" # no _shellcheck
  echo
  sleep 300
done
