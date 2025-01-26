#!/usr/bin/env bash

[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
set -o xtrace

# ONWER='ovn-kubernetes'
ONWER='flavio-fernandes'

# IMG_PREFIX="ghcr.io/${ONWER}/ovn-kubernetes/ovn-kube-ubuntu"
IMG_PREFIX="ghcr.io/${ONWER}/ovn-kubernetes/ovn-kube-fedora"

helm repo add ovnk https://${ONWER}.github.io/ovn-kubernetes
# helm repo update ovnk
helm search repo ovnk --versions --devel

# 1.0.0
TAG='release-1.0'
docker pull ${IMG_PREFIX}:${TAG}
kind load docker-image ${IMG_PREFIX}:${TAG}

helm pull ovnk/ovn-kubernetes --untar --version "1.0.0" && \
cd ovn-kubernetes && \
helm install ovn-kubernetes . -f values.yaml  \
   --set k8sAPIServer="https://$(kubectl get pods -n kube-system -l component=kube-apiserver -o jsonpath='{.items[0].status.hostIP}'):6443" \
   --set global.image.repository=${IMG_PREFIX} \
   --set global.image.tag=${TAG}

# kubectl -n ovn-kubernetes wait --for=condition=ready -l app=ovnkube-node pod --timeout=300s
/vagrant/provision/wait_for_pods.sh -n ovn-kubernetes -l "app=ovnkube-node"
