#!/usr/bin/env bash

[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
set -o xtrace

kind_get_nodes() {
  kind get nodes --name "${KIND_CLUSTER_NAME}" | grep -v external-load-balancer
}

label_ovn_single_node_zones() {
  VALUES_FILE=$1

  # do not label nodes, unless we are running interconnect mode
  [ "${VALUES_FILE}" == "values-single-node-zone.yaml" ] || { echo "label_ovn_single_node_zones not needed"; return; }

  KIND_NODES=$(kind_get_nodes)
  for n in $KIND_NODES; do
    kubectl label node "${n}" k8s.ovn.org/zone-name=${n} --overwrite
  done
}

install_online_ovn_kubernetes_crds() {
  # NOTE: When you update vendoring versions for the ANP & BANP APIs, we must update the version of the CRD we pull from in the below URL
  echo "Installing policy networking CRD ..."
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/network-policy-api/v0.1.5/config/crd/experimental/policy.networking.k8s.io_adminnetworkpolicies.yaml
  kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/network-policy-api/v0.1.5/config/crd/experimental/policy.networking.k8s.io_baselineadminnetworkpolicies.yaml

  # Multus
  echo "Installing Multus CRD ..."
  kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/refs/heads/master/deployments/multus-daemonset-thick.yml

  echo "Installing IPAMClaim CRD ..."
  ipamclaims_manifest="https://raw.githubusercontent.com/k8snetworkplumbingwg/ipamclaims/v0.4.0-alpha/artifacts/k8s.cni.cncf.io_ipamclaims.yaml"
  kubectl apply -f "$ipamclaims_manifest"

  echo "Installing multi-network-policy CRD ..."
  mpolicy_manifest="https://raw.githubusercontent.com/k8snetworkplumbingwg/multi-networkpolicy/master/scheme.yml"
  kubectl apply -f "$mpolicy_manifest"
}

# for admin network policy, we need external crds
install_online_ovn_kubernetes_crds

# ONWER='ovn-kubernetes'
ONWER='flavio-fernandes'

# IMG_PREFIX="ghcr.io/${ONWER}/ovn-kubernetes/ovn-kube-ubuntu"
IMG_PREFIX="ghcr.io/${ONWER}/ovn-kubernetes/ovn-kube-fedora"

helm repo add ovnk https://${ONWER}.github.io/ovn-kubernetes
# helm repo update ovnk
helm search repo ovnk --versions --devel

# comment out one of the 2 lines below to use right helm chart version
TAG='release-1.0'; HVER='1.0.0'; VALUES_FILE='values.yaml'
# TAG='master' ; HVER='1.1.0-alpha' ; VALUES_FILE='values-single-node-zone.yaml'

# for ovn interconnect, nodes must be labeled with their corresponding zones
label_ovn_single_node_zones ${VALUES_FILE}

docker pull ${IMG_PREFIX}:${TAG}
kind load docker-image ${IMG_PREFIX}:${TAG}

helm pull ovnk/ovn-kubernetes --untar --version ${HVER} && \
cd ovn-kubernetes && \
helm install ovn-kubernetes . -f ${VALUES_FILE}  \
   --set tags.ovs-node=false \
   --set k8sAPIServer="https://$(kubectl get pods -n kube-system -l component=kube-apiserver -o jsonpath='{.items[0].status.hostIP}'):6443" \
   --set global.enableAdminNetworkPolicy=true \
   --set global.enableMultiNetwork=true \
   --set global.image.repository=${IMG_PREFIX} \
   --set global.image.tag=${TAG}

# kubectl -n ovn-kubernetes wait --for=condition=ready -l app=ovnkube-node pod --timeout=300s
/vagrant/provision/wait_for_pods.sh -n ovn-kubernetes -l "app=ovnkube-node"
