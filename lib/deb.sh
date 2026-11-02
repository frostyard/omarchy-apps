#!/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later
# Shared deb-assembly helper for omarchy-apps builds.
#
# make_deb NAME VERSION DESCRIPTION STAGE_DIR [EXTRA_DEPENDS] [INPUTS]
#
# STAGE_DIR is a rootfs-shaped tree (usr/bin/..., usr/share/...). Runtime
# library dependencies are computed with dpkg-shlibdeps from every ELF
# executable/library in the stage, then EXTRA_DEPENDS (comma-separated) is
# appended for dependencies shlibdeps cannot see (dlopen'd libraries, QML
# module plugins, executables invoked at runtime). Package versions carry a
# -frostyard<timestamp> suffix so rebuilds of the same upstream version
# still sort newer in apt (same convention as frostyard/bootc-debian).
#
# INPUTS is the digest of the app's inputs (app_inputs in lib/inputs.sh). It
# is written as the user field Frostyard-Inputs, which dpkg-deb accepts and
# aptly copies into the Packages index; plan.sh reads it back to decide
# whether the app changed. Empty or absent: no field.
set -euo pipefail

make_deb() {
    local name="$1" version="$2" desc="$3" stage="$4" extra_depends="${5:-}" inputs="${6:-}"
    local arch stamp debver pkgdir shlibs

    if [[ -n "$inputs" && ! "$inputs" =~ ^sha256:[0-9a-f]{64}$ ]]; then
        echo "make_deb: INPUTS is not sha256:<64 hex>: $inputs" >&2
        return 1
    fi

    arch="$(dpkg --print-architecture)"
    stamp="${SOURCE_DATE_EPOCH:+$(date -u -d "@$SOURCE_DATE_EPOCH" +%Y%m%d%H%M%S)}"
    stamp="${stamp:-$(date -u +%Y%m%d%H%M%S)}"
    debver="${version}-frostyard${stamp}"
    pkgdir="$stage"

    mkdir -p "$pkgdir/DEBIAN"

    # dpkg-shlibdeps needs a debian/control at the tree root it scans from.
    local scratch
    scratch="$(mktemp -d)"
    mkdir -p "$scratch/debian"
    touch "$scratch/debian/control"

    shlibs=""
    local elfs=()
    while IFS= read -r f; do
        file -b "$f" | grep -q 'ELF .* \(executable\|shared object\)' && elfs+=("$f")
    done < <(find "$pkgdir/usr" -type f \( -perm -u+x -o -name '*.so*' \) 2>/dev/null)
    if ((${#elfs[@]} > 0)); then
        (cd "$scratch" && dpkg-shlibdeps -O "${elfs[@]}" 2>/dev/null | sed 's/^shlibs:Depends=//') >"$scratch/deps" || true
        shlibs="$(cat "$scratch/deps")"
    fi
    rm -rf "$scratch"

    local depends="$shlibs"
    if [[ -n "$extra_depends" ]]; then
        depends="${depends:+$depends, }$extra_depends"
    fi

    {
        printf 'Package: %s\n' "$name"
        printf 'Version: %s\n' "$debver"
        printf 'Architecture: %s\n' "$arch"
        printf 'Maintainer: Frostyard <noreply@frostyard.org>\n'
        printf 'Section: utils\n'
        printf 'Priority: optional\n'
        [[ -n "$depends" ]] && printf 'Depends: %s\n' "$depends"
        [[ -n "$inputs" ]] && printf 'Frostyard-Inputs: %s\n' "$inputs"
        printf 'Description: %s\n' "$desc"
        printf ' Packaged for the frostyard APT repository by frostyard/omarchy-apps.\n'
    } >"$pkgdir/DEBIAN/control"

    find "$pkgdir" -type d -exec chmod 755 {} +
    mkdir -p "$DIST"
    dpkg-deb --build --root-owner-group -Zzstd "$pkgdir" "$DIST/${name}_${debver}_${arch}.deb"
    echo "built $DIST/${name}_${debver}_${arch}.deb"
}
