#!/bin/bash
# Tests for lib/inputs.sh, plan.sh and lib/deb.sh. No network: every Packages
# index and stage tree is written here, in a temporary directory.
# Runs on ubuntu-latest (dpkg, jq, file) and locally.
set -euo pipefail

SRCDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

failures=0
ok() { printf 'ok: %s\n' "$*"; }
fail() { printf 'not ok: %s\n' "$*" >&2; failures=$((failures + 1)); }

# The digest plan.sh computes for APP, from the repository or a copy of it.
digest() { # digest APP [SRCDIR]
    bash -c '
        set -euo pipefail
        SRCDIR="$1"
        source "$SRCDIR/lib/inputs.sh"
        app_inputs "$2"
    ' _ "${2:-$SRCDIR}" "$1"
}

copy_repo() { # copy_repo DIR
    mkdir -p "$1"
    tar -C "$SRCDIR" --exclude=.git --exclude=dist -cf - . | tar -C "$1" -xf -
}

index=0
new_index() {
    index=$((index + 1))
    PKG="$WORK/Packages.$index"
    : >"$PKG"
}

# add_stanza PACKAGE VERSION [FROSTYARD_INPUTS]
add_stanza() {
    {
        printf 'Package: %s\n' "$1"
        printf 'Version: %s\n' "$2"
        printf 'Architecture: amd64\n'
        [[ -z "${3:-}" ]] || printf 'Frostyard-Inputs: %s\n' "$3"
        printf 'Description: test fixture\n'
        printf ' A continuation line, which is not a field.\n'
        printf '\n'
    } >>"$PKG"
}

# A stanza in the layout aptly publishes: checksums in the middle, the field
# near the end, Description last with its continuation line.
add_published_stanza() { # add_published_stanza PACKAGE VERSION [FROSTYARD_INPUTS]
    {
        printf 'Package: %s\n' "$1"
        printf 'Priority: optional\n'
        printf 'Section: utils\n'
        printf 'Maintainer: Frostyard <noreply@frostyard.org>\n'
        printf 'Architecture: amd64\n'
        printf 'Version: %s\n' "$2"
        printf 'Filename: pool/main/v/%s/%s_%s_amd64.deb\n' "$1" "$1" "$2"
        printf 'Size: 8239674\n'
        printf 'SHA256: %s\n' "$OTHER"
        [[ -z "${3:-}" ]] || printf 'Frostyard-Inputs: %s\n' "$3"
        printf 'Description: test fixture\n'
        printf ' Packaged for the frostyard APT repository by frostyard/omarchy-apps.\n'
        printf '\n'
    } >>"$PKG"
}

run_plan() {
    PLAN_STATUS=0
    bash "$SRCDIR/plan.sh" "$@" >"$WORK/out" 2>"$WORK/err" || PLAN_STATUS=$?
}

decision() { awk -v a="$1" '$1 == a { print $2 }' "$WORK/err"; }
code() { local t='`'; printf '%s%s%s' "$t" "$1" "$t"; } # a Markdown code span

expect_status() { # expect_status WHAT WANT
    if [[ "$PLAN_STATUS" == "$2" ]]; then ok "$1"; else fail "$1: exit $PLAN_STATUS, want $2"; fi
}
expect_list() { # expect_list WHAT JSON
    if [[ "$(cat "$WORK/out")" == "$2" ]]; then ok "$1"; else fail "$1: got $(cat "$WORK/out"), want $2"; fi
}
expect_decision() { # expect_decision WHAT APP DECISION
    local got
    got="$(decision "$2")"
    if [[ "$got" == "$3" ]]; then ok "$1"; else fail "$1: $2 is '${got}', want '$3'"; fi
}
expect_stderr_line() { # expect_stderr_line WHAT LINE
    if grep -qxF -- "$2" "$WORK/err"; then ok "$1"; else fail "$1: no line '$2' in: $(tr '\n' ';' <"$WORK/err")"; fi
}
expect_same() { # expect_same WHAT GOT WANT
    if [[ "$2" == "$3" ]]; then ok "$1"; else fail "$1: got '$2', want '$3'"; fi
}
expect_different() { # expect_different WHAT GOT THAN
    if [[ "$2" != "$3" ]]; then ok "$1"; else fail "$1: both '$2'"; fi
}
expect_nonzero() { # expect_nonzero WHAT STATUS
    if [[ "$2" != 0 ]]; then ok "$1"; else fail "$1: exit 0"; fi
}

DIG_V="$(digest voxtype)"
DIG_M="$(digest moonlight-qt)"
OTHER="sha256:$(printf '0%.0s' {1..64})"

if [[ "$DIG_V" =~ ^sha256:[0-9a-f]{64}$ && "$DIG_M" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    ok "app_inputs prints sha256:<64 hex>"
else
    fail "app_inputs printed '$DIG_V' and '$DIG_M'"
fi
expect_different "the two apps have different digests" "$DIG_V" "$DIG_M"

# --- plan.sh decisions -------------------------------------------------------

new_index
add_stanza cliamp 9.9.9-frostyard20260101000000
run_plan --packages "$PKG"
expect_status "nothing published: exit 0" 0
expect_list "nothing published: both apps publish" '["moonlight-qt","voxtype"]'
expect_decision "nothing published: voxtype changed" voxtype changed
expect_decision "nothing published: moonlight-qt changed" moonlight-qt changed
expect_stderr_line "nothing published: the stderr line" \
    "voxtype changed inputs=$DIG_V newest=none newest-inputs=none"

new_index
add_stanza voxtype 1.1.1-frostyard20260101000000 "$DIG_V"
add_stanza moonlight-qt 6.2.0-frostyard20260101000000 "$OTHER"
run_plan --packages "$PKG"
expect_list "same digest on the newest version: only the other app publishes" '["moonlight-qt"]'
expect_decision "same digest: voxtype unchanged" voxtype unchanged
expect_decision "other digest: moonlight-qt changed" moonlight-qt changed
expect_stderr_line "same digest: the stderr line" \
    "voxtype unchanged inputs=$DIG_V newest=1.1.1-frostyard20260101000000 newest-inputs=$DIG_V"

new_index
add_stanza voxtype 1.1.1-frostyard20260101000000 "$OTHER"
run_plan --packages "$PKG"
expect_decision "another digest: voxtype changed" voxtype changed

new_index
add_published_stanza voxtype 1.1.1-frostyard20260101000000 "$DIG_V"
add_published_stanza voxtype 1.1.0-frostyard20251201000000 "$OTHER"
run_plan --packages "$PKG"
expect_decision "a stanza in aptly's layout is read: newest matches, unchanged" voxtype unchanged
expect_stderr_line "the field is found wherever aptly puts it" \
    "voxtype unchanged inputs=$DIG_V newest=1.1.1-frostyard20260101000000 newest-inputs=$DIG_V"

new_index
add_stanza voxtype 1.1.1-frostyard20260101000000 "$DIG_V"
add_stanza voxtype 1.1.2-frostyard20260102000000 "$OTHER"
run_plan --packages "$PKG"
expect_decision "an older version matches but the newest differs: changed" voxtype changed
expect_stderr_line "the newest version is the one compared" \
    "voxtype changed inputs=$DIG_V newest=1.1.2-frostyard20260102000000 newest-inputs=$OTHER"

new_index
add_stanza voxtype 1.1.1-frostyard20260101000000 "$DIG_V"
add_stanza voxtype 1.1.2-frostyard20260102000000
run_plan --packages "$PKG"
expect_decision "the newest version has no field: changed" voxtype changed
expect_stderr_line "the stderr line names the missing field" \
    "voxtype changed inputs=$DIG_V newest=1.1.2-frostyard20260102000000 newest-inputs=none"

# dpkg --compare-versions, not sort -V: 6.10.0 is newer than 6.9.0.
new_index
add_stanza moonlight-qt 6.10.0-frostyard20260102000000 "$OTHER"
add_stanza moonlight-qt 6.9.0-frostyard20260101000000 "$DIG_M"
run_plan --packages "$PKG"
expect_decision "6.10.0 is newer than 6.9.0: changed" moonlight-qt changed
expect_stderr_line "6.10.0 is the newest" \
    "moonlight-qt changed inputs=$DIG_M newest=6.10.0-frostyard20260102000000 newest-inputs=$OTHER"

new_index
add_stanza moonlight-qt 6.9.0-frostyard20260101000000 "$OTHER"
add_stanza moonlight-qt 6.10.0-frostyard20260102000000 "$DIG_M"
run_plan --packages "$PKG"
expect_decision "6.10.0 comes last in the file too: unchanged" moonlight-qt unchanged

# sort -V puts 1.1.0~rc1 above 1.1.0; dpkg --compare-versions does not.
new_index
add_stanza voxtype 1.1.1-frostyard20260101000000 "$OTHER"
add_stanza voxtype 1.1.1~rc1-frostyard20260102000000 "$DIG_V"
run_plan --packages "$PKG"
expect_decision "a ~ pre-release is older than the plain version: changed" voxtype changed
expect_stderr_line "the plain version is the newest" \
    "voxtype changed inputs=$DIG_V newest=1.1.1-frostyard20260101000000 newest-inputs=$OTHER"

# Versions of other packages in the index do not decide anything, whatever
# the value of their Frostyard-Inputs.
new_index
add_stanza voxtype 1.1.1-frostyard20260101000000 "$DIG_V"
add_stanza cliamp 99.0.0-frostyard20260101000000 "$OTHER"
add_stanza moonlight-qt 6.2.0-frostyard20260101000000 "$DIG_M"
run_plan --packages "$PKG"
expect_list "versions of other packages are ignored" '[]'
expect_decision "versions of other packages are ignored: voxtype" voxtype unchanged
expect_decision "versions of other packages are ignored: moonlight-qt" moonlight-qt unchanged

# --- --rebuild ---------------------------------------------------------------

run_plan --packages "$PKG" --rebuild voxtype
expect_status "--rebuild of an unchanged app: exit 0" 0
expect_list "--rebuild of an unchanged app: forced into the publish list" '["voxtype"]'
expect_decision "--rebuild of an unchanged app: forced" voxtype forced
expect_decision "--rebuild leaves the other app alone" moonlight-qt unchanged

run_plan --packages "$PKG" --rebuild ""
expect_status "--rebuild '' : exit 0" 0
expect_list "--rebuild '' means none" '[]'

new_index
run_plan --packages "$PKG" --rebuild moonlight-qt
expect_decision "--rebuild of a changed app: forced" moonlight-qt forced

run_plan --packages "$PKG" --rebuild nosuchapp
expect_nonzero "--rebuild of an unknown app fails" "$PLAN_STATUS"
expect_list "--rebuild of an unknown app prints nothing" ''

run_plan --packages "$PKG" --rebuild "moonlight-qt voxtype"
expect_nonzero "--rebuild of two names in one value fails" "$PLAN_STATUS"

run_plan --rebuild voxtype
expect_nonzero "no --packages fails" "$PLAN_STATUS"

# --- --summary ---------------------------------------------------------------

new_index
add_stanza voxtype 1.1.1-frostyard20260101000000 "$DIG_V"
printf '# Job summary\n' >"$WORK/summary.md"
run_plan --packages "$PKG" --rebuild voxtype --summary "$WORK/summary.md"
run_plan --packages "$PKG" --summary "$WORK/summary.md"
row="| voxtype | forced | $(code "$DIG_V") | $(code 1.1.1-frostyard20260101000000) | $(code "$DIG_V") |"
if grep -qF -- "$row" "$WORK/summary.md"; then
    ok "--summary appends a Markdown row per app"
else
    fail "--summary table lacks the voxtype row: $(cat "$WORK/summary.md")"
fi
expect_same "--summary appends, it does not overwrite" \
    "$(grep -cF '### Which apps this run publishes' "$WORK/summary.md")" 2
expect_same "--summary keeps what was there" "$(head -1 "$WORK/summary.md")" '# Job summary'

# --- app_inputs --------------------------------------------------------------

copy_repo "$WORK/copy"

for f in build.sh lib/deb.sh download/verified-download.sh apps/voxtype.sh; do
    cp "$SRCDIR/$f" "$WORK/copy/$f"
    printf '\n# input test\n' >>"$WORK/copy/$f"
    expect_different "a change to $f changes the digest" "$(digest voxtype "$WORK/copy")" "$DIG_V"
    cp "$SRCDIR/$f" "$WORK/copy/$f"
done
expect_same "restoring the files restores the digest" "$(digest voxtype "$WORK/copy")" "$DIG_V"

jq '.voxtype.version = "9.9.9"' "$SRCDIR/download/checksums.json" >"$WORK/copy/download/checksums.json"
expect_different "a change to the pin of the app changes the digest" \
    "$(digest voxtype "$WORK/copy")" "$DIG_V"
expect_same "a change to the pin of the app leaves the other app alone" \
    "$(digest moonlight-qt "$WORK/copy")" "$DIG_M"

jq '.["moonlight-qt"].sha256 = "changed"' "$SRCDIR/download/checksums.json" >"$WORK/copy/download/checksums.json"
expect_same "a change to the pin of another app leaves the digest alone" \
    "$(digest voxtype "$WORK/copy")" "$DIG_V"
cp "$SRCDIR/download/checksums.json" "$WORK/copy/download/checksums.json"

if digest nosuchapp >/dev/null 2>&1; then
    fail "app_inputs accepts an unknown app"
else
    ok "app_inputs fails for an unknown app"
fi

jq '.voxtype = null' "$SRCDIR/download/checksums.json" >"$WORK/copy/download/checksums.json"
if digest voxtype "$WORK/copy" >/dev/null 2>&1; then
    fail "app_inputs accepts a null pin"
else
    ok "app_inputs fails when the pin is null"
fi
cp "$SRCDIR/download/checksums.json" "$WORK/copy/download/checksums.json"

# --- make_deb ----------------------------------------------------------------

# build_fixture_deb DIST [INPUTS]: a tiny stage (one text file under
# usr/share), so dpkg-shlibdeps is never called.
build_fixture_deb() {
    local dist="$1" want="${2:-}" stage
    stage="$(mktemp -d "$WORK/stage.XXXXXX")"
    mkdir -p "$stage/usr/share/doc/voxtype"
    printf 'fixture\n' >"$stage/usr/share/doc/voxtype/README"
    (
        set -euo pipefail
        DIST="$dist"
        # shellcheck source=lib/deb.sh
        source "$SRCDIR/lib/deb.sh"
        if [[ -n "$want" ]]; then
            make_deb voxtype 1.1.1 "test fixture" "$stage" "" "$want" >/dev/null
        else
            make_deb voxtype 1.1.1 "test fixture" "$stage" >/dev/null
        fi
    )
}

if command -v dpkg-deb >/dev/null && command -v file >/dev/null; then
    with_inputs="sha256:$(printf 'a%.0s' {1..64})"
    build_fixture_deb "$WORK/deb/with" "$with_inputs"
    build_fixture_deb "$WORK/deb/without"
    deb="$(find "$WORK/deb/with" -name 'voxtype_1.1.1-frostyard*_*.deb' -print -quit)"
    expect_same "make_deb writes Frostyard-Inputs" \
        "$(dpkg-deb -f "$deb" Frostyard-Inputs)" "$with_inputs"
    if [[ "$(dpkg-deb -f "$deb" Version)" =~ ^1\.1\.1-frostyard[0-9]{14}$ ]]; then
        ok "make_deb keeps the -frostyard<timestamp> suffix"
    else
        fail "make_deb wrote version $(dpkg-deb -f "$deb" Version)"
    fi
    # A build without the argument still works: the field is then absent.
    plain="$(find "$WORK/deb/without" -name 'voxtype_1.1.1-frostyard*_*.deb' -print -quit)"
    expect_same "make_deb without the argument writes no field" \
        "$(dpkg-deb -f "$plain" Frostyard-Inputs)" ""
else
    echo "skip: the make_deb test needs dpkg-deb and file"
fi

# --- result ------------------------------------------------------------------

if ((failures > 0)); then
    printf '\n%d test(s) failed\n' "$failures" >&2
    exit 1
fi
printf '\nall tests passed\n'
