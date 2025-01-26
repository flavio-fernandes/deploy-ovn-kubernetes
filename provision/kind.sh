#!/usr/bin/env bash

[ $EUID -eq 0 ] || { echo 'must be root' >&2; exit 1; }

set -o errexit
set -o xtrace

[ -x "/usr/local/bin/kind" ] && { echo "kind already installed"; exit 0; }

[ $(uname -m) = x86_64 ] && curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
chmod +x /usr/local/bin/kind
