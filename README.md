# deploy-ovn-kubernetes

A collection of scripts and configurations to deploy [OVN-Kubernetes](https://github.com/ovn-org/ovn-kubernetes) as a CNI plugin for a [Kind](https://kind.sigs.k8s.io/) cluster. This setup also leverages [Multus](https://github.com/k8snetworkplumbingwg/multus-cni) to add multiple network attachments to each pod.

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Prerequisites](#prerequisites)
4. [Quick Start (Vagrant)](#quick-start-vagrant)
5. [Manual Deployment Steps](#manual-deployment-steps)
6. [Notes on Helm Repo](#notes-on-helm-repo)
7. [Cluster Topology](#cluster-topology)
8. [Example Usage](#example-usage)
9. [Observing Network Traffic](#observing-network-traffic)
10. [Branches and Differences](#branches-and-differences)

---

## Overview

This repository automates the creation of:
- A **Kind**-based Kubernetes cluster, running in Docker.
- **OVN-Kubernetes** as the default CNI, via Helm charts hosted on a GitHub Pages repo.
- **Multus** for secondary networks, with sample pods demonstrating multiple interfaces.

The [Vagrantfile](./Vagrantfile) included here provisions a Fedora VM that installs Docker, Kind, Helm, and runs helper scripts to build the cluster.
If Vagrant is not your thing, see [Manual Deployment Steps](#manual-deployment-steps) section below.

---

## Features

- **Vagrant-based** deployment: One command (`vagrant up`) to provision a pre-configured VM.
- **Helm-based** installation of OVN-Kubernetes: Pulls charts from a GitHub Pages Helm repo.
- **Support for multiple networks** via Multus: Demonstrates additional interfaces (whereabouts MACVLAN and a second OVN overlay).
- **Configurable**: Update Helm values, images, or CRDs in the scripts and rerun.

---

## Prerequisites

- A linux distro with 4 Gb+ RAM, capable of deploying Kubernetes via Kind. More info below.
- Optional: [Vagrant](https://www.vagrantup.com/) (with a provider like **libvirt** or **VirtualBox**).

---

## Quick Start (Vagrant)

1. **Clone** this repo:
   ```bash
   git clone https://github.com/flavio-fernandes/deploy-ovn-kubernetes.git
   cd deploy-ovn-kubernetes
   ```

2. **Launch** the VM:
   ```bash
   vagrant up
   vagrant ssh
   ```

3. **Initialize** the cluster inside the VM:
   ```bash
   ./start_cluster.sh
   ./start_test_pods.sh
   ```

You now have a **Kind** cluster with OVN-Kubernetes. You can verify the pods:
```bash
kubectl get pods -o wide
```

---

## Manual Deployment Steps

If you want to set everything up on a non-Vagrant system:

1. Clone this repo under /vagrant, as shown below:
   ```bash
   cd
   git clone https://github.com/flavio-fernandes/deploy-ovn-kubernetes.git && \
   ln -s /vagrant/provision/start_cluster.sh && \
   ln -s /vagrant/provision/start_test_pods.sh

   # Option 1: hard bind
   sudo mkdir -pv /vagrant
   sudo chown "$USER":"$USER" /vagrant
   sudo mount --bind ~/deploy-ovn-kubernetes /vagrant

   sudo mkdir -pv /home/vagrant
   sudo chown "$USER":"$USER" /home/vagrant
   sudo mount --bind ~ /home/vagrant

   Option 2: symbolic link
   sudo ln -s ~/deploy-ovn-kubernetes /vagrant
   sudo ln -s ~ /home/vagrant
   ```

2. **Install** Docker (or another container runtime), [Git](https://git-scm.com/), [kubectl](https://www.geeksforgeeks.org/install-and-set-up-kubectl-on-linux/), [Kind](https://kind.sigs.k8s.io/), and [Helm](https://helm.sh/).
   See [provision/setup.sh](./provision/setup.sh) and the scripts it calls for reference.

---

## Notes on Helm Repo

This repository uses a Helm chart hosted on GitHub Pages to simplify the deployment of OVN-Kubernetes.
The [start_cluster.sh](./provision/start_cluster.sh) script automatically handles adding the Helm repo and installing the necessary components, so no additional steps are required.
Running the following command is only for users who want to explore available versions and become familiar with the Helm chart:

```bash
helm repo add ovnk https://flavio-fernandes.github.io/ovn-kubernetes
helm search repo ovnk --versions --devel
```

In the near future, use the official Helm chart hosted at [ovn-kubernetes](https://github.com/ovn-kubernetes/ovn-kubernetes/pull/4971).
For detailed steps on how the Helm chart is utilized in this project, refer to the [provision/start_cluster_cni_ovnk.sh](./provision/start_cluster_cni_ovnk.sh) script.

---

## Cluster Topology

The diagram below shows the cluster layout, highlighting three interfaces for each sample pod.
**Please know that the exact addresses vary in each deployment, so take them with a grain of salt!**
Each sample pod has three interfaces:

```text
                       +-----------------------------------+
                       | kind-control-plane                |
Docker                 | Docker IP: 172.18.0.2             |
Underlay               | (control-plane node)              |
(172.18.0.0/16)        |   - ovnDb pod                     |
                       +-----------------------------------+
                                          |
                +--------------------------------------------------+
                | kind-worker                                      |
                | Docker IP: 172.18.0.5                            |
Underlay        | Connection:                                      |
                |   - eth0: Docker network (172.18.0.0/16)         |
                |   - eth1: Secondary network (192.168.1.0/24)     |
                |                                                  |
Overlay         |   samplepod1:                                    |
                |      ├─ eth0 => 10.244.0.6    (Default OVN)      |
                |      ├─ eth1 => 192.168.1.201 (whereabouts-conf) |
                |      └─ eth2 => 10.245.3.4    (ovn-again-conf)   |
                +--------------------------------------------------+
                                          |
                +--------------------------------------------------+
                | kind-worker2                                     |
                | Docker IP: 172.18.0.3                            |
Underlay        | Connection:                                      |
                |   - eth0: Docker network (172.18.0.0/16)         |
                |   - eth1: Secondary network (192.168.1.0/24)     |
                |                                                  |
Overlay         |   samplepod2:                                    |
                |      ├─ eth0 => 10.244.2.8    (Default OVN)      |
                |      ├─ eth1 => 192.168.1.200 (whereabouts-conf) |
                |      └─ eth2 => 10.245.2.3    (ovn-again-conf)   |
                +--------------------------------------------------+
                                          |
                +--------------------------------------------------+
                | kind-worker3                                     |
                | Docker IP: 172.18.0.4                            |
Underlay        | Connection:                                      |
                |   - eth0: Docker network (172.18.0.0/16)         |
                |   - eth1: Secondary network (192.168.1.0/24)     |
                |                                                  |
Overlay         |   samplepod3:                                    |
                |      ├─ eth0 => 10.244.3.6    (Default OVN)      |
                |      ├─ eth1 => 192.168.1.202 (whereabouts-conf) |
                |      └─ eth2 => 10.245.0.4    (ovn-again-conf)   |
                +--------------------------------------------------+
```

- Underlay (`eth0`): Represents the Docker network (`172.18.0.0/16`) used for inter-node communication and OVN overlay encapsulation (e.g., Geneve traffic).
- Secondary Underlay (`eth1`): Represents the secondary network (`192.168.1.0/24`), used directly by the whereabouts-conf attachment.
- Overlay (`eth0`): Represents the OVN overlay network (`10.244.x.x`), with packets traversing nodes encapsulated over underlay eth0 (`Geneve`).
- Overlay (`eth2`): Represents the OVN overlay network (`10.245.x.x`), with packets traversing nodes encapsulated over underlay eth0 (`Geneve`).

---

## Example Usage

```bash
# Unset KIND_CLUSTER_NAME to ensure worker nodes are named as kind-worker.
# The start_test_pods.sh script assumes that in order to place samplepods in specific nodes.
unset KIND_CLUSTER_NAME

./start_cluster.sh
./start_test_pods.sh

kubectl get nodes
kubectl get pods -o wide
kubectl exec -it samplepod1 -- ip a

# To cleanup
kind delete clusters kind ; \
rm -rf ~/ovn-kubernetes
```

---

## Observing Network Traffic

This section provides insights into network communication at different layers, including:

1. **Secondary Underlay (`eth1`)** - Direct layer 2 connectivity between nodes using the whereabouts-conf network.
2. **Overlay (`eth2`)** - Traffic encapsulated via Geneve, traversing `eth0` between nodes.

### Ping Testing Between Pods

We begin by testing connectivity between `samplepod1` and `samplepod2` using both `eth1` (secondary underlay) and `eth2` (overlay via Geneve).

First, extract the target pod’s IP addresses dynamically:

```bash
extract_pod_ip_from_annotation() {
    local pod_name="$1"
    local namespace="${2:-default}"
    local interface="${3:-eth2}"

    kubectl get pod "$pod_name" -n "$namespace" -o json |
        jq -r '.metadata.annotations["k8s.v1.cni.cncf.io/network-status"]' |
        jq -r --arg iface "$interface" '.[] | select(.interface == $iface) | .ips[0]'
}

NAMESPACE=$(kubectl config view --minify --output 'jsonpath={..namespace}') ; NAMESPACE=${NAMESPACE:-default}
DST_IP_ETH0=$(extract_pod_ip_from_annotation samplepod2 $NAMESPACE eth0)
DST_IP_ETH1=$(extract_pod_ip_from_annotation samplepod2 $NAMESPACE eth1)
DST_IP_ETH2=$(extract_pod_ip_from_annotation samplepod2 $NAMESPACE eth2)

# Run ping commands in the background
nohup kubectl exec -i samplepod1 -- ping -c 3600 -q $DST_IP_ETH0 >/dev/null 2>&1 &
nohup kubectl exec -i samplepod1 -- ping -c 3600 -q $DST_IP_ETH1 >/dev/null 2>&1 &
nohup kubectl exec -i samplepod1 -- ping -c 3600 -q $DST_IP_ETH2 >/dev/null 2>&1 &
```

### Capturing Traffic

To understand packet flow, we will capture ICMP traffic on different interfaces:

#### Capturing Traffic on eth1 (Secondary Underlay)

The `eth1` interface on the worker nodes carries direct layer 2 traffic between pods using the `whereabouts-conf` network.

To capture ICMP packets exchanged between `samplepod1` and `samplepod2`:

```bash
sudo dnf install -y --quiet tcpdump ; # Install tcpdump, if needed

IPNS=$(docker inspect --format '{{ .State.Pid }}' kind-worker)
sudo nsenter -t ${IPNS} -n tcpdump -envvi eth1 icmp
```

#### Example Output:
```bash
22:10:19.243328 16:d8:e1:f6:e7:3a > 72:41:ad:29:94:ac, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 64, id 7058, offset 0, flags [DF], proto ICMP (1), length 84)
    192.168.1.201 > 192.168.1.200: ICMP echo request, id 50, seq 15, length 64
22:10:19.243359 72:41:ad:29:94:ac > 16:d8:e1:f6:e7:3a, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 64, id 41641, offset 0, flags [none], proto ICMP (1), length 84)
    192.168.1.200 > 192.168.1.201: ICMP echo reply, id 50, seq 15, length 64


whereabouts-conf
22:10:18.243200 192.168.1.201 > 192.168.1.200: ICMP echo request
22:10:18.243238 192.168.1.200 > 192.168.1.201: ICMP echo reply
```


#### Capturing Encapsulated Traffic on eth0 (Geneve Overlay)

Packets between `samplepod1` and `samplepod2` traverse the underlay network (`eth0`) encapsulated in Geneve.

To inspect the encapsulated ICMP packets:

```bash
IPNS=$(docker inspect --format '{{ .State.Pid }}' kind-worker)
sudo nsenter -t ${IPNS} -n tcpdump -envvi eth0 geneve
```

#### Expected Output (Example of Encapsulated ICMP Traffic in Geneve Tunnel):

```bash
17:56:59.742366 02:42:ac:12:00:05 > 02:42:ac:12:00:03, ethertype IPv4 (0x0800), length 156: (tos 0x0, ttl 64, id 65033, offset 0, flags [DF], proto UDP (17), length 142)
    172.18.0.5.8520 > 172.18.0.3.geneve: [bad udp cksum 0x58b8 -> 0x4d7f!] Geneve, Flags [C], vni 0x1, proto TEB (0x6558), options [class Open Virtual Networking (OVN) (0x102) type 0x80(C) l
en 8 data 00040007]
        0a:58:0a:f4:02:01 > 0a:58:0a:f4:02:08, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 63, id 37325, offset 0, flags [DF], proto ICMP (1), length 84)
    10.244.0.6 > 10.244.2.8: ICMP echo request, id 49, seq 64, length 64

17:56:59.742441 02:42:ac:12:00:03 > 02:42:ac:12:00:05, ethertype IPv4 (0x0800), length 156: (tos 0x0, ttl 64, id 34387, offset 0, flags [DF], proto UDP (17), length 142)
    172.18.0.3.8520 > 172.18.0.5.geneve: [bad udp cksum 0x58b8 -> 0x4b7f!] Geneve, Flags [C], vni 0x1, proto TEB (0x6558), options [class Open Virtual Networking (OVN) (0x102) type 0x80(C) l
en 8 data 00060005]
        0a:58:0a:f4:03:01 > 0a:58:0a:f4:00:06, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 63, id 48056, offset 0, flags [none], proto ICMP (1), length 84)
    10.244.2.8 > 10.244.0.6: ICMP echo reply, id 49, seq 64, length 64


Default OVN
Geneve, Flags [C], vni 0xf, proto TEB (0x6558), options [class OVN (0x102)]
    10.244.0.6 > 10.244.2.8: ICMP echo request
    10.245.2.5 > 10.244.0.6: ICMP echo reply
```

```bash
17:56:58.741927 02:42:ac:12:00:05 > 02:42:ac:12:00:03, ethertype IPv4 (0x0800), length 156: (tos 0x0, ttl 64, id 65027, offset 0, flags [DF], proto UDP (17), length 142)
    172.18.0.5.5134 > 172.18.0.3.geneve: [bad udp cksum 0x58b8 -> 0x50b6!] Geneve, Flags [C], vni 0xf, proto TEB (0x6558), options [class Open Virtual Networking (OVN) (0x102) type 0x80(C) l
en 8 data 00050008]
        0a:58:0a:f5:02:01 > 0a:58:0a:f5:02:03, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 63, id 20396, offset 0, flags [DF], proto ICMP (1), length 84)
    10.245.3.4 > 10.245.2.3: ICMP echo request, id 55, seq 63, length 64

17:56:58.742007 02:42:ac:12:00:03 > 02:42:ac:12:00:05, ethertype IPv4 (0x0800), length 156: (tos 0x0, ttl 64, id 33537, offset 0, flags [DF], proto UDP (17), length 142)
    172.18.0.3.5134 > 172.18.0.5.geneve: [bad udp cksum 0x58b8 -> 0x4ab6!] Geneve, Flags [C], vni 0xf, proto TEB (0x6558), options [class Open Virtual Networking (OVN) (0x102) type 0x80(C) l
en 8 data 00070006]
        0a:58:0a:f5:03:01 > 0a:58:0a:f5:03:04, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 63, id 6171, offset 0, flags [none], proto ICMP (1), length 84)
    10.245.2.3 > 10.245.3.4: ICMP echo reply, id 55, seq 63, length 64


ovn-again-conf
Geneve, Flags [C], vni 0xf, proto TEB (0x6558), options [class OVN (0x102)]
    10.245.3.4 > 10.245.2.3: ICMP echo request
    10.245.2.3 > 10.245.3.4: ICMP echo reply
```

This output shows that ICMP traffic is wrapped in Geneve packets (`proto UDP`), indicating cross-node communication over the overlay.

### Cleanup

To terminate the background ping processes, run:

```bash
kubectl exec samplepod1 -- pkill -f "ping -c 3600 -q"
```

---

## Branches and Differences

Multiple branches may exist for different configurations:
```bash
git branch -a
```
- **main** – The default stable branch.
- **build-ovn-from-source** – Build container images.
- **helm-ovn-from-source** - Helm install from cloned repo instead of Helm Release Chart.
- **cilium** – Use Cilium as CNI instead of OVN-Kubernetes. Cilium provides an alternative CNI with eBPF-based networking.
- **distro-rocky8** – Use Rocky Vagrant box instead of Fedora.
- **no-ovs-pods** – Use kind node image that includes ovs, skipping the need for the ovs-node pods.
- **ovn-interconnect** – Use OVN-Interconnect feature.
