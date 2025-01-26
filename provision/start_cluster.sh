#!/usr/bin/env bash

[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
set -o xtrace

## kind create cluster --config=/vagrant/kind-config.yaml

cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: true

  # non-ovnk cnis, like Cilium, need kubeProxyMode.
  # use kubeProxyMode none only when deploying kind for ovn-kubernetes
  kubeProxyMode: "none"

  # podSubnet: 10.244.0.0/16
  # serviceSubnet: 10.96.0.0/16
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF

/vagrant/provision/config_kind.sh

# /vagrant/provision/start_cluster_cni_cilium.sh

# /vagrant/provision/start_cluster_cni_ovnk_build_locally.sh
/vagrant/provision/start_cluster_cni_ovnk.sh

# Wait for all nodes to be ready (10 minutes timeout)
timeout=600
interval=10
elapsed=0
while true; do
    ready_nodes=$(kubectl get nodes --no-headers | grep -c "Ready")
    total_nodes=$(kubectl get nodes --no-headers | wc -l)

    if [ "$ready_nodes" -eq "$total_nodes" ] && [ "$total_nodes" -ge 3 ]; then
        echo "All nodes are Ready."
        break
    fi

    if [ "$elapsed" -ge "$timeout" ]; then
        echo "Timeout waiting for nodes to become ready." >&2
        exit 1
    fi

    echo "Waiting for nodes to become ready... (${elapsed}s elapsed)"
    sleep $interval
    elapsed=$((elapsed + interval))
done

/vagrant/provision/start_cluster_multus.sh
