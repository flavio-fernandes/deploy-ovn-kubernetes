#!/usr/bin/env bash

[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
set -o xtrace

sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io

sudo usermod -a -G docker $(whoami)

systemctl is-active --quiet docker || {
    sudo systemctl enable --now docker
}

CONFIG="/home/vagrant/.bashrc.d/docker.sh"
mkdir -p $(dirname $CONFIG)
cat << EOT > $CONFIG
alias podman=docker
EOT
