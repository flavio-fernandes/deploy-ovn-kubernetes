#!/usr/bin/env bash
#

[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
# set -o xtrace

[ -d /home/vagrant ] || { echo "PROBLEM, vagrant homedir is not present"; exit 1; }

mkdir -pv /home/vagrant/.ssh
touch /home/vagrant/.ssh/authorized_keys
## Add a public key, if wanted...
## echo '' >> /home/vagrant/.ssh/authorized_keys ; \
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJsBAVYeEz0cJ4YyhWajUvkXSz2/zWIdfl5sHfTLF9PL ffernandes@nvidia.com' >> /home/vagrant/.ssh/authorized_keys ; \
chmod 644 /home/vagrant/.ssh/authorized_keys ; \
chmod 755 /home/vagrant/.ssh

cd /vagrant/provision || cd "$(dirname $0)"

sudo ./pkgs.sh
sudo ./golang.sh
./docker.sh
sudo ./kind.sh
./kube.sh
./get_helm.sh

ln -svf /vagrant/provision/start_cluster.sh ~/
ln -svf /vagrant/provision/start_test_pods.sh ~/

echo ok
