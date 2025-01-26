#!/usr/bin/env bash

[ $EUID -eq 0 ] || { echo 'must be root' >&2; exit 1; }

set -o errexit
# set -o xtrace

dnf install -y --allowerasing vim emacs-nox tmux curl wget tmate python3-pip dnsutils make patch git jq bash-completion
dnf groupinstall -y "Development Tools"

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv -vf ./kubectl /usr/local/bin/kubectl

cat << EOT >> /root/.emacs
;; use C-x g for goto-line
(global-set-key "\C-xg" 'goto-line)
(setq line-number-mode t)
(setq column-number-mode t)
(setq make-backup-files nil)
;; tabs are evail
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq indent-line-function 'insert-tab)
(setq-default c-basic-offset 4)
EOT

[ -e /home/vagrant/.emacs ] || {
    cp -v {/root,/home/vagrant}/.emacs
    chown vagrant:vagrant /home/vagrant/.emacs
}

cat << EOT >> /root/.vimrc
set expandtab
set tabstop=2
set shiftwidth=2
EOT

[ -e /home/vagrant/.vimrc ] || {
    cp -v {/root,/home/vagrant}/.vimrc
    chown vagrant:vagrant /home/vagrant/.vimrc
}
