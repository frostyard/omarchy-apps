# Development

Use this procedure to build one package, inspect a publication plan and run the repository gates.

## Install tools

```sh
mise install
```

The pinned tools are shellcheck, actionlint, jq and Node.js. Node.js runs the
vendored README checker; it needs no package dependencies.

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

The baseline gate checks the packaging marker and runs the unchanged core
README checker for rules R1 to R12 of the
[README spec](https://github.com/frostyard/core/blob/main/docs/specs/readme.md)
(baseline B17, core ADR-0072). Run it or its focused gate tests directly:

```sh
node tests/lib/check-readme.mjs .
bash tests/check-baseline-test.sh --readme
```

`tests/lib/check-readme.mjs` is copied from
[`frostyard/core@b40d872d20084527849242a8bcc6b074cd5333a9`](https://github.com/frostyard/core/blob/b40d872d20084527849242a8bcc6b074cd5333a9/.agents/skills/frostyard-readme/scripts/check-readme.mjs).
`tests/check-baseline.sh` verifies its SHA-256 before invoking Node.js, and
`make ci` runs that gate and its negative tests. Never edit the copy by hand:
copy an update from core and update the source revision and hash together.
The focused tests cover each rule, the 1000-word boundary, the copy's integrity
and invocation failure propagation. The checker and its tests use no network.
