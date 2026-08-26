#!/bin/bash
# Build one omarchy-apps package from its pinned, verified source.
#
# Runs as root inside a debian:trixie container (CI or local):
#   podman run --rm -v "$PWD":/src -w /src debian:trixie bash build.sh <app>
#
# Each app lives in apps/<name>.sh and defines:
#   APP_DESC           one-line package description
#   APP_EXTRA_DEPENDS  comma-separated Depends beyond dpkg-shlibdeps output
#                      (dlopen'd libs, QML module plugins, runtime tools)
#   APP_SMOKE          command run against the installed package in CI
#   app_deps()         apt-get install of build dependencies
#   app_build()        fetch via verified_download / pinned git, build, and
#                      stage into $STAGE (rootfs-shaped: usr/bin, ...)
#
# Output: dist/<name>_<version>-frostyard<stamp>_<arch>.deb
# (override location with DIST=/path).
set -euo pipefail
[[ "${DEBUG_BUILD:-0}" == "1" ]] && set -x

APP="${1:?usage: build.sh <app>}"
SRCDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="${DIST:-$SRCDIR/dist}"

[[ -f "$SRCDIR/apps/$APP.sh" ]] || { echo "unknown app: $APP (no apps/$APP.sh)" >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install --no-install-recommends --yes \
    build-essential curl ca-certificates dpkg-dev jq git file zstd

# Pinned Rust toolchain for the Rust apps (installed on demand by rust_deps).
# Trixie's rustc 1.85 predates several upstream MSRVs; rustup verifies
# toolchain signatures on download. Bump alongside app version bumps that
# demand newer.
RUST_VERSION="1.96.0"
rust_deps() {
    apt-get install --no-install-recommends --yes rustup pkg-config
    rustup default "$RUST_VERSION"
}

# Go apps: trixie's golang-go plus GOTOOLCHAIN=auto -- go.mod's toolchain
# directive is honored and the downloaded toolchain is verified against the
# Go checksum database.
go_deps() {
    apt-get install --no-install-recommends --yes golang-go
    export GOTOOLCHAIN=auto GOFLAGS=-buildvcs=false
}

WORK="$(mktemp -d)"
STAGE="$WORK/stage"
mkdir -p "$STAGE"
trap 'rm -rf "$WORK"' EXIT

# shellcheck source=download/verified-download.sh
source "$SRCDIR/download/verified-download.sh"
# shellcheck source=lib/deb.sh
source "$SRCDIR/lib/deb.sh"
# shellcheck source=/dev/null
source "$SRCDIR/apps/$APP.sh"

VERSION="$(jq -r --arg a "$APP" '.[$a].version' "$SRCDIR/download/checksums.json")"
[[ -n "$VERSION" && "$VERSION" != null ]] || { echo "no version pinned for $APP" >&2; exit 1; }

app_deps
app_build
make_deb "$APP" "$VERSION" "$APP_DESC" "$STAGE" "${APP_EXTRA_DEPENDS:-}"
