# fedora-dev-light

A personal [bootc](https://github.com/bootc-dev/bootc) image based on Fedora Atomic with a lightweight desktop environment (currently [Sway](https://swaywm.org/), via [Fedora Sway Atomic](https://quay.io/repository/fedora-ostree-desktops/sway-atomic)), plus opinionated dev tooling on top.

Published at: `ghcr.io/corruptedbit/fedora-dev-light`

## What's in the image

Sway Atomic already ships a complete, minimal Wayland setup (Sway compositor, waybar, launcher, terminal, ...), so this image only adds tooling on top:

- Similar to [uCore](https://github.com/ublue-os/ucore): `podman-compose`, `firewalld`, `tailscale`, `distrobox`
- **Visual Studio Code** (from Microsoft's official repo)
- **Zed** editor (via the [Terra](https://terra.fyi/) repo, enabled only during the build)
- **Custom Nerd Fonts**: [CascadiaCode](https://github.com/microsoft/cascadia-code), FantasqueSansMono, Mononoki, copied into `/usr/share/fonts` and registered with `fc-cache`
- **Flatpak**, with Flathub pre-configured as a system remote on first boot (`system_files/usr/lib/systemd/system/flathub-setup.service`) — Fedora Atomic Desktops only ship their own remote by default, not Flathub
- **Homebrew** (via [ublue-os/brew](https://github.com/ublue-os/brew)), extracted to `/var/home/linuxbrew/.linuxbrew` on first boot, with automatic daily update/upgrade timers
- **`ujust`** (via [ublue-os/packages](https://github.com/ublue-os/packages)' `ublue-os-just`/`ublue-os-luks`, from the `ublue-os/packages` COPR), which brings in ublue-os's standard recipes (`ujust --list` to see them all) — `update`, `clean`, `distrobox-*`, `toolbox-*`, plus nvidia/akmods ones that are no-ops on this image since we don't ship either
- Custom `ujust` recipes on top (`system_files/usr/share/ublue-os/just/60-custom.just`, overriding `ublue-os-just`'s own placeholder of the same name):
  - `ujust install-dev-tools` — Claude Code, starship, git-graph, zellij (via Homebrew)
  - `ujust enable-starship` — wires up starship in `~/.bashrc`
  - `ujust install-utilities` — chezmoi, yt-dlp, htop, cmatrix (Homebrew) + Gear Lever, Bitwarden (Flatpak)
- **Custom wallpaper** ("Rancho") under `/usr/share/wallpapers`

All package installation logic lives in [`build_files/build.sh`](./build_files/build.sh), which is invoked from the [`Containerfile`](./Containerfile) during the image build.

## Switching to this image

From a system already running a bootc image (Fedora Atomic, Bazzite, Bluefin, Aurora, ...):

```bash
sudo bootc switch ghcr.io/corruptedbit/fedora-dev-light:latest
```

Reboot to apply.

## Repository layout

- **`Containerfile`** — entrypoint for the image build. Pulls in `build_files/` and `system_files/` via a `FROM scratch` context stage (`ctx`), then runs `build.sh` against the `quay.io/fedora-ostree-desktops/sway-atomic:44` base image.
- **`build_files/build.sh`** — installs packages (dev tooling, Flatpak/Flathub, `ujust`), copies `system_files/` into the image root, enables `podman.socket` + `flathub-setup.service`.
- **`system_files/`** — mirrors the final image's root filesystem: Flathub remote definition, fonts, wallpaper, custom `ujust` recipes. Its contents are merged into `/` by `build.sh`, not by a separate `COPY` in the `Containerfile`.
- **`image-template.env`** — build metadata (`IMAGE_NAME`, `REPO_ORGANIZATION`, description, keywords, default tag, BIB image), loaded by the `Justfile` via `set dotenv-filename`.
- **`Justfile`** — local build/test commands (see below).
- **`disk_config/`** — `bootc-image-builder` configs:
  - `disk.toml` — for `qcow2`/`raw` VM images (20 GiB filesystem minimum).
  - `iso.toml` — for the bare-metal/VM installer ISO. Its kickstart `%post` runs `bootc switch` to this image's `ghcr.io` tag once Anaconda finishes installing the base OS. Note: `bootc-image-builder`'s `anaconda-iso` type **always partitions automatically** ("installs to the first disk found") regardless of which Anaconda modules are enabled. It is **not** a fully interactive installer like the official Fedora/Bazzite media. Almost all other Anaconda modules (user creation, network, timezone, ...) are enabled for maximum flexibility during install.

## Building and pushing locally

This image is currently built and published entirely from a local machine — no CI/GitHub Actions involved for now.

Requires [`just`](https://just.systems/) and `podman`.

```bash
# Build the image
just build fedora-dev-light latest

# Optional: rechunk for smaller incremental updates
sudo just ostree-rechunk fedora-dev-light latest

# Push to GHCR
just push fedora-dev-light latest

# Sign the image (requires cosign.key locally)
sudo just sign fedora-dev-light latest

# Or do all of the above in one go
just release fedora-dev-light latest
```

### Building a VM image or ISO

```bash
# QCOW2 for a VM
just build-qcow2 fedora-dev-light latest

# Bare-metal/VM installer ISO (points at the local build by default;
# pass a ghcr.io/... reference to build straight from the published image)
just build-iso fedora-dev-light latest
```

## Container signing

Builds are signed locally with [cosign](https://docs.sigstore.dev/cosign/overview/) via `just sign` (see above). The private key (`cosign.key`) stays local and is gitignored; the public key is committed as `cosign.pub` so pulled images can be verified.

## Credit

This repository started from [ublue-os/image-template](https://github.com/ublue-os/image-template). A copy of the original template README is kept at [`README-ublue.md`](./README-ublue.md) for reference on generic bootc-image-template usage (cosign setup, ArtifactHub indexing, full `Justfile` recipe reference, etc.).
