<!-- readme-kind: packaging -->
# omarchy-apps

[![CI](https://github.com/frostyard/omarchy-apps/actions/workflows/ci.yml/badge.svg)](https://github.com/frostyard/omarchy-apps/actions/workflows/ci.yml)

`omarchy-apps` builds Debian packages for the Omarchy ecosystem from pinned, verified upstream sources. It publishes the packages to the [Frostyard APT repository](https://repository.frostyard.org/debian/) through [apt-publisher](https://github.com/frostyard/apt-publisher). snosi installs them in its `voxtype` and `moonlight` sysexts.

**Status:** in production. It publishes from `main`.

**Documentation:** [docs/README.md](docs/README.md)

## What it publishes

| Package | What it is | Component | Codename |
| --- | --- | --- | --- |
| `voxtype` | AI dictation package for a snosi sysext | `main` | `trixie` |
| `moonlight-qt` | Game-streaming client package for a snosi sysext | `main` | `trixie` |

## Install

Add the Frostyard APT repository once, then install a package:

```sh
sudo curl -fsSLo /etc/apt/keyrings/frostyard.gpg https://repository.frostyard.org/debian/frostyard.gpg
printf 'Types: deb\nURIs: https://repository.frostyard.org/debian/\nSuites: trixie\nComponents: main\nSigned-By: /etc/apt/keyrings/frostyard.gpg\n' | sudo tee /etc/apt/sources.list.d/frostyard.sources
sudo apt update
sudo apt install voxtype
```

## Add a package

Add only a package that a snosi image or sysext uses. Core ADR-0066 records this publication boundary; the package and upstream source procedure is in [docs/design/overview.md](docs/design/overview.md#add-an-app).

## How it works

Pinned upstream versions and SHA-256 hashes live in `download/checksums.json`. A main run compares each package's `Frostyard-Inputs` digest with the published package, attaches changed `.deb` files to a release and asks apt-publisher to publish them. [docs/design/overview.md](docs/design/overview.md) has the build and publication details.

## Develop

```sh
mise install
make ci
podman run --rm -v "$PWD":/src -w /src debian:trixie bash build.sh voxtype
```

The full local procedure is in [docs/runbooks/development.md](docs/runbooks/development.md).

## Where to go next

- [AGENTS.md](AGENTS.md): the rules for agents and contributors.
- [docs/README.md](docs/README.md): the decisions, designs, specs and plans.
- [SECURITY.md](SECURITY.md): report a vulnerability privately.
- [LICENSE](LICENSE): MIT.
