#!/usr/bin/env bash

[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
# set -o xtrace

sudo dnf -y install dnf-plugins-core
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl is-active --quiet docker || {
    sudo systemctl start docker
    sudo systemctl enable docker

    sudo groupadd docker ||:
    sudo usermod -aG docker $(whoami)
    newgrp docker ||:
    # docker ps
}

CONFIG="/home/vagrant/.bashrc.d/docker.sh"
mkdir -p $(dirname $CONFIG)
cat << EOT > $CONFIG
alias podman=docker
EOT
