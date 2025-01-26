#!/usr/bin/env bash

[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

# grab cilium binaries, if needed
[ -x /usr/local/bin/cilium ] || /vagrant/provision/cilium.sh

set -o errexit
set -o xtrace

helm repo add cilium https://helm.cilium.io/ ||:

# helm search repo cilium --versions --devel

docker pull quay.io/cilium/cilium:v1.16.5
kind load docker-image quay.io/cilium/cilium:v1.16.5

helm install cilium cilium/cilium --version 1.16.5 \
 --namespace kube-system \
 --set image.pullPolicy=IfNotPresent \
 --set ipam.mode=kubernetes \
 --set cni.exclusive=false

## cilium status
## cilium hubble enable
cilium status --wait
## time cilium connectivity test

# helm ls -A
