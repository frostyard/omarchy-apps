#!/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later
# Input digest of one app: the files that shape its .deb, plus its own pin.
#
# app_inputs APP prints "sha256:<64 hex>". SRCDIR is the repository root.
# The digest covers, in this fixed order:
#   build.sh, lib/deb.sh, download/verified-download.sh, apps/APP.sh
# and the app's own entry in download/checksums.json. A pin change for a
# different app leaves the digest alone, so that app alone is republished.
set -euo pipefail

app_inputs() {
    local app="${1:?usage: app_inputs <app>}"
    local src="${SRCDIR:?app_inputs needs SRCDIR (the repository root)}"
    local pin f

    [[ -f "$src/apps/$app.sh" ]] || { echo "unknown app: $app (no apps/$app.sh)" >&2; return 1; }
    [[ -f "$src/download/checksums.json" ]] || { echo "no $src/download/checksums.json" >&2; return 1; }

    pin="$(jq -cS --arg a "$app" '.[$a]' "$src/download/checksums.json")"
    [[ -n "$pin" && "$pin" != null ]] || { echo "no pin for $app in download/checksums.json" >&2; return 1; }

    {
        for f in build.sh lib/deb.sh download/verified-download.sh "apps/$app.sh"; do
            printf '%s  %s\n' "$(sha256sum "$src/$f" | cut -d' ' -f1)" "$f"
        done
        printf '%s\n' "$pin"
    } | sha256sum | cut -d' ' -f1 | sed 's/^/sha256:/'
}
