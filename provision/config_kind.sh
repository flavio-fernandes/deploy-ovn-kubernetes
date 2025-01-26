[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
# set -o xtrace

export KIND_CLUSTER_NAME=$(kind get clusters | head -1)

kind_get_nodes() {
  kind get nodes --name "${KIND_CLUSTER_NAME}" | grep -v external-load-balancer
}

create_docker_l2_networks() {
    docker network create --driver=bridge kind-nodes-eth1-lan ||:
    docker network create --driver=bridge kind-nodes-eth2-lan ||:

    KIND_NODES=$(kind_get_nodes)
    for i in $KIND_NODES; do echo "$i"; \
        docker network connect kind-nodes-eth1-lan $i
        docker network connect kind-nodes-eth2-lan $i
    done
}

# https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files
sudo sysctl fs.inotify.max_user_watches=1048576
sudo sysctl fs.inotify.max_user_instances=512

create_docker_l2_networks
