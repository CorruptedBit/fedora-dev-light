#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# Install packages

## dnf5's config-manager/copr plugins aren't necessarily installed by default.
dnf5 install -y dnf5-plugins

## Smiliar to ucore
dnf5 install -y podman-compose firewalld tailscale distrobox flatpak

## ujust + inherited recipes (update, clean, distrobox, toolbox, nvidia, akmods)
## from ublue-os, via their packages COPR (see https://github.com/ublue-os/packages).
dnf5 copr enable -y ublue-os/packages
dnf5 install -y just ublue-os-just ublue-os-luks
dnf5 copr disable -y ublue-os/packages

#### Example for enabling a System Unit File
systemctl enable podman.socket

## Add Flathub as a system-wide flatpak remote on first boot (Fedora Atomic
## Desktops, like plain Fedora, only ship their own remote by default, not
## Flathub -- see system_files/usr/lib/systemd/system/flathub-setup.service).
systemctl enable flathub-setup.service

## Re-apply our system_files on top of everything installed above: ublue-os-just
## ships its own placeholder 60-custom.just (not %config(noreplace)), which would
## otherwise silently overwrite ours.
cp -avf "/ctx/system_files"/. /
