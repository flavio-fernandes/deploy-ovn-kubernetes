[ $EUID -eq 0 ] && { echo 'must not be root' >&2; exit 1; }

set -o errexit
# set -o xtrace

sudo dnf install -y openssl

# https://helm.sh/docs/intro/install/
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | sh

