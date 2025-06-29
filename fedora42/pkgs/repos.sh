#!/usr/bin/env bash

jq -r .packages[] /usr/share/rpm-ostree/treefile.json >/usr/local/share/bootc/packages-base

# Set up additional repositories
dnf -y install dnf5-plugins
dnf -y copr enable wezfurlong/wezterm-nightly
dnf -y config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
