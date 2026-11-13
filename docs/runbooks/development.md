# Development

Use this procedure to build one package, inspect a publication plan and run the repository gates.

## Install tools

```sh
mise install
```

The pinned tools are shellcheck, actionlint and jq.

## Build locally

`build.sh` runs `apt-get` and must run as root. Run it in the Debian 13 container:

```sh
podman run --rm -v "$PWD":/src -w /src debian:trixie bash build.sh voxtype
podman run --rm -v "$PWD":/src -w /src debian:trixie bash build.sh moonlight-qt
```

Each command writes a `.deb` to `dist/`. The upstream URLs, versions and SHA-256 hashes come from `download/checksums.json`.

## Plan a publication

`plan.sh --packages FILE` reads an exported published Packages index:

```sh
bash plan.sh --packages Packages
```

It prints one JSON array of apps to publish. It writes one decision line per app to stderr: `unchanged`, `changed` or `forced`. The command needs `jq` and `dpkg`; it needs no network.

## Smoke-test a built package

`smoke.sh APP` runs the recipe's `APP_SMOKE` against an installed package. It installs `APP_SMOKE_DEPS` itself, so run it as root in a container with the `.deb` already installed:

```sh
podman run --rm -v "$PWD":/src:Z -w /src debian:forky bash -c \
  'apt-get update && apt-get install --yes ./dist/*.deb && bash smoke.sh moonlight-qt'
```

Add `SMOKE_APPS_DIR=/path` to run a recipe from another directory.

## Run the gates

Run the same credential-free gate as CI:

```sh
make ci
```

`make ci` runs `verify`. `verify` runs `lint` and `test`. `lint` runs shellcheck, actionlint and both baseline scripts. `test` runs `bash tests/run.sh` without network access.

Run the package tests directly when needed:

```sh
bash tests/run.sh
```

The README checker runs from a checkout of frostyard/core at `origin/main`:

```sh
node <core checkout>/.agents/skills/frostyard-readme/scripts/check-readme.mjs .
```
