#!/bin/bash
logit () {
  echo "$1" >> /tmp/cni-inspect.log
}

logit "-------------- CNI call for $CNI_COMMAND on $CNI_CONTAINERID"
logit "CNI_COMMAND: $CNI_COMMAND"
logit "CNI_CONTAINERID: $CNI_CONTAINERID"
logit "CNI_NETNS: $CNI_NETNS"
logit "CNI_IFNAME: $CNI_IFNAME"
logit "CNI_ARGS: $CNI_ARGS"
logit "CNI_PATH: $CNI_PATH"
logit "-- cni config"
stdin=$(cat /dev/stdin)
logit "$stdin"
# Just a valid response with fake info.
echo '{
  "cniVersion": "0.3.1",
  "interfaces": [
      {
          "name": "eth0",
          "sandbox": "'"$CNI_NETNS"'"
      }
  ],
  "ips": [
      {
          "version": "4",
          "address": "192.0.2.22/24",
          "gateway": "192.0.2.1",
          "interface": 0
      }
  ]
}'

