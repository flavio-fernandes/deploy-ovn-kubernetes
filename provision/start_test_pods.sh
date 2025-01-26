#!/usr/bin/env bash

[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
# set -o xtrace

usage() {
    cat <<EOF
Usage: $0 [options]
Options:
  -h          Show this help message
  clean       Remove the NetworkAttachmentDefinition and test pods
EOF
}

# Load the namespace from the current context if none is provided
NAMESPACE=$(kubectl config view --minify --output 'jsonpath={..namespace}')
NAMESPACE=${NAMESPACE:-default}

clean_up() {
    kubectl delete pod samplepod1 -n "$NAMESPACE" --ignore-not-found &
    kubectl delete pod samplepod2 -n "$NAMESPACE" --ignore-not-found &
    kubectl delete pod samplepod3 -n "$NAMESPACE" --ignore-not-found &
    kubectl delete network-attachment-definition -n "$NAMESPACE" whereabouts-conf --ignore-not-found
    echo "Cleaned up test pods and NetworkAttachmentDefinition."
    exit 0
}

create_pod() {
    local pod_name=$1
    local node_name=${2:-kind-worker}
    if ! kubectl get pod "$pod_name" -n "$NAMESPACE" &>/dev/null; then
        cat <<EOF | kubectl apply -n "$NAMESPACE" -f -
apiVersion: v1
kind: Pod
metadata:
  name: $pod_name
  labels:
    name: $pod_name
  annotations:
    k8s.v1.cni.cncf.io/networks: whereabouts-conf@eth1
spec:
  nodeSelector:
    kubernetes.io/hostname: $node_name
  containers:
  - name: $pod_name
    command: ["/bin/ash", "-c", "trap : TERM INT; sleep infinity & wait"]
    image: alpine
EOF
        echo "Pod $pod_name created."
    else
        echo "Pod $pod_name already exists."
    fi
}

if [[ "$1" == "-h" ]]; then
    usage
    exit 0
elif [[ "$1" == "clean" ]]; then
    clean_up
fi

# Create NetworkAttachmentDefinition if it doesn't exist
if ! kubectl get network-attachment-definition whereabouts-conf -n "$NAMESPACE" &>/dev/null; then
    cat <<EOF | kubectl apply -n "$NAMESPACE" -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: whereabouts-conf
spec:
  config: '{
      "cniVersion": "0.3.0",
      "name": "whereaboutsexample",
      "type": "macvlan",
      "master": "eth1",
      "mode": "bridge",
      "ipam": {
        "type": "whereabouts",
        "range": "192.168.1.0/24",
        "range_start": "192.168.1.200"
      }
  }'
EOF
    echo "NetworkAttachmentDefinition whereabouts-conf created."
else
    echo "NetworkAttachmentDefinition whereabouts-conf already exists."
fi

# Create test pods
create_pod "samplepod1"
create_pod "samplepod2" kind-worker2
create_pod "samplepod3" kind-worker3

# Wait for both pods to become ready
/vagrant/provision/wait_for_pods.sh -n "$NAMESPACE" -l "name=samplepod1"
/vagrant/provision/wait_for_pods.sh -n "$NAMESPACE" -l "name=samplepod2"
/vagrant/provision/wait_for_pods.sh -n "$NAMESPACE" -l "name=samplepod3"

kubectl get pods -owide

echo kubectl exec samplepod1
kubectl exec samplepod1 -- ip a
echo --
echo kubectl exec samplepod2
kubectl exec samplepod2 -- ip a
echo --
echo kubectl exec samplepod3
kubectl exec samplepod2 -- ip a
echo --

echo Test connectivity from samplepod1
kubectl exec samplepod1 -- sh -c "ping -c 2 -W 3 192.168.1.200" || exit 1
kubectl exec samplepod1 -- sh -c "ping -c 2 -W 3 192.168.1.201" || exit 1
kubectl exec samplepod1 -- sh -c "ping -c 2 -W 3 192.168.1.202" || exit 1
echo

echo ok
