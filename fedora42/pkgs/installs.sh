#!/usr/bin/env bash
set -e -o pipefail

EZA_VERSION=${EZA_VERSION:-"latest"}

pkg_file=/usr/local/share/bootc/packages.json

# Install wanted packages
pkgs_str=$(jq -r '.add | flatten | @sh' "${pkg_file}")
declare -a pkgs="($pkgs_str)"
dnf -y --no-docs --refresh install --allowerasing "${pkgs[@]}"

# Remove unwanted/uneeded/unuseful
pkgs_str=$(jq -r '.remove | flatten | @sh' "${pkg_file}")
declare -a pkgs="($pkgs_str)"
dnf -y remove "${pkgs[@]}"

# This is just a large and uneeded binary
rm /usr/bin/wezterm-gui

# eza isn't in repositories
curl -sSL "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz" |
  tar -xz -C /usr/local/bin &&
  chmod +x /usr/local/bin/eza

dnf -y autoremove
dnf clean all
