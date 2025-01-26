#!/usr/bin/env bash

[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

# set -o errexit
# set -o xtrace
set -euxo pipefail

# OVNKDIR='/vagrant/ovn-kubernetes.git'

OVNKDIR='/home/vagrant/ovn-kubernetes'
cd
git clone --depth 1 https://github.com/ovn-kubernetes/ovn-kubernetes.git && \
cd ovn-kubernetes

cd ${OVNKDIR}/dist/images

# build image (or just pull it)
make ubuntu
docker tag ovn-kube-ubuntu:latest ghcr.io/ovn-kubernetes/ovn-kubernetes/ovn-kube-ubuntu:master
# docker pull ghcr.io/ovn-kubernetes/ovn-kubernetes/ovn-kube-ubuntu:master

kind load docker-image ghcr.io/ovn-kubernetes/ovn-kubernetes/ovn-kube-ubuntu:master

cd ${OVNKDIR}/helm/ovn-kubernetes
helm install ovn-kubernetes . -f values-no-ic.yaml \
    --set k8sAPIServer="https://$(kubectl get pods -n kube-system -l component=kube-apiserver -o jsonpath='{.items[0].status.hostIP}'):6443" \
    --set global.image.repository=ghcr.io/ovn-kubernetes/ovn-kubernetes/ovn-kube-ubuntu --set global.image.tag=master

# kubectl -n ovn-kubernetes wait --for=condition=ready -l app=ovnkube-node pod --timeout=300s
/vagrant/provision/wait_for_pods.sh -n ovn-kubernetes -l "app=ovnkube-node"
