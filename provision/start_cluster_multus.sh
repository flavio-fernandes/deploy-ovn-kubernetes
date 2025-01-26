#!/usr/bin/env bash

[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
set -o xtrace

# Multus
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/refs/heads/master/deployments/multus-daemonset-thick.yml
# kubectl -n kube-system wait --for=condition=ready -l name=multus pod --timeout=300s
/vagrant/provision/wait_for_pods.sh -n kube-system -l "name=multus"

# Reference CNI plugins
kubectl create -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/refs/heads/master/e2e/templates/cni-install.yml.j2
# kubectl -n kube-system wait --for=condition=ready -l name=cni-plugins pod --timeout=300s
/vagrant/provision/wait_for_pods.sh -n kube-system -l "name=cni-plugins"

# Whereabouts (aka where aboots in Canada :))
kubectl create -f https://raw.githubusercontent.com/k8snetworkplumbingwg/whereabouts/refs/heads/master/doc/crds/daemonset-install.yaml \
        -f https://raw.githubusercontent.com/k8snetworkplumbingwg/whereabouts/refs/heads/master/doc/crds/whereabouts.cni.cncf.io_overlappingrangeipreservations.yaml \
        -f https://raw.githubusercontent.com/k8snetworkplumbingwg/whereabouts/refs/heads/master/doc/crds/whereabouts.cni.cncf.io_ippools.yaml
# kubectl -n kube-system wait --for=condition=ready -l name=whereabouts pod --timeout=300s
/vagrant/provision/wait_for_pods.sh -n kube-system -l "name=whereabouts"

# Start a test pod using NAD
/vagrant/provision/start_test_pods.sh || { echo 'Test pod using CNI did not go well' >&2; exit 1; }

# Delete test pod using NAD
/vagrant/provision/start_test_pods.sh clean
