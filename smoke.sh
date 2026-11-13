#!/bin/bash
# Smoke-test 1 installed omarchy-apps package.
#
#   bash smoke.sh <app>
#
# Runs the recipe's APP_SMOKE against the package that is already installed, in
# the container under test: debian:trixie in the build job, debian:forky in the
# smoke-forky job. A gate that passes without a working app is worse than no
# gate, so this script fails when the app cannot start:
#
#   - apps/<app>.sh is loaded with errors NOT ignored (no `|| true`), so a
#     recipe that fails to source fails the smoke;
#   - a missing or empty APP_SMOKE fails instead of running an empty command;
#   - APP_SMOKE_DEPS, when the recipe sets it, is installed with apt-get first:
#     packages the smoke needs but the package must not depend on, such as
#     xvfb for a GUI app;
#   - `bash -c APP_SMOKE` must exit 0.
#
# SMOKE_APPS_DIR overrides the recipe directory (the tests use it with fake
# recipes). This script is not part of any app's input digest (lib/inputs.sh),
# so a smoke change re-runs the gate and republishes nothing.
set -euo pipefail

APP="${1:?usage: smoke.sh <app>}"
SRCDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS_DIR="${SMOKE_APPS_DIR:-$SRCDIR/apps}"

export DEBIAN_FRONTEND=noninteractive

recipe="$APPS_DIR/$APP.sh"
[[ -f "$recipe" ]] || {
    echo "smoke: unknown app: $APP (no $recipe)" >&2
    exit 1
}

# shellcheck source=/dev/null
if ! source "$recipe"; then
    echo "smoke: cannot load $recipe" >&2
    exit 1
fi

smoke="${APP_SMOKE:-}"
if [[ -z "$smoke" ]]; then
    echo "smoke: $APP sets no APP_SMOKE; every app must prove that it starts" >&2
    exit 1
fi

smoke_deps="${APP_SMOKE_DEPS:-}"
if [[ -n "$smoke_deps" ]]; then
    read -r -a deps <<<"$smoke_deps"
    echo "smoke: $APP: apt-get install --no-install-recommends --yes ${deps[*]}"
    apt-get install --no-install-recommends --yes "${deps[@]}"
fi

echo "smoke: $APP: bash -c '$smoke'"
bash -c "$smoke"
