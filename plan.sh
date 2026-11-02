#!/bin/bash
# Decide which apps a run publishes, from the published Packages index.
#
# Usage: plan.sh --packages FILE [--rebuild APP] [--summary FILE]
#
#   --packages FILE  a Debian Packages index (the published trixie main amd64 one)
#   --rebuild APP    also publish APP, whether or not its inputs changed
#                    (empty or absent: no app is forced)
#   --summary FILE   append a Markdown table of the decision, for
#                    $GITHUB_STEP_SUMMARY
#
# stdout: one JSON array, compact and sorted, of the apps to publish
#         (changed + forced).
# stderr: one line per app:
#         APP DECISION inputs=<digest> newest=<version or none> newest-inputs=<field or none>
#
# An app is unchanged when the Frostyard-Inputs field of its newest published
# version equals the digest of its inputs (lib/inputs.sh). No published
# version, no field, or another value: changed. Newest is chosen with
# dpkg --compare-versions, not sort -V.
set -euo pipefail

SRCDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/inputs.sh
source "$SRCDIR/lib/inputs.sh"

usage() { echo "usage: plan.sh --packages FILE [--rebuild APP] [--summary FILE]" >&2; exit 2; }

packages="" rebuild="" summary=""
while (($# > 0)); do
    case "$1" in
        --packages) (($# >= 2)) || usage; packages="$2"; shift 2 ;;
        --rebuild) (($# >= 2)) || usage; rebuild="$2"; shift 2 ;;
        --summary) (($# >= 2)) || usage; summary="$2"; shift 2 ;;
        -h | --help) usage ;;
        *) echo "unknown argument: $1" >&2; usage ;;
    esac
done

[[ -n "$packages" ]] || usage
[[ -f "$packages" ]] || { echo "no such Packages file: $packages" >&2; exit 1; }

apps=()
for f in "$SRCDIR"/apps/*.sh; do
    [[ -f "$f" ]] || continue
    apps+=("$(basename "$f" .sh)")
done
((${#apps[@]} > 0)) || { echo "no apps in $SRCDIR/apps" >&2; exit 1; }
mapfile -t apps < <(printf '%s\n' "${apps[@]}" | LC_ALL=C sort)

case " ${apps[*]} " in
    *" $rebuild "*) ;;
    *) [[ -z "$rebuild" ]] || { echo "unknown app for --rebuild: $rebuild" >&2; exit 1; } ;;
esac

# Package<TAB>Version<TAB>Frostyard-Inputs for every stanza of the index.
# Multi-line field continuations start with a space and carry nothing we need.
stanzas="$(mktemp)"
trap 'rm -f "$stanzas"' EXIT
awk '
    function flush() {
        if (pkg != "") printf "%s\t%s\t%s\n", pkg, ver, inputs
        pkg = ""; ver = ""; inputs = ""
    }
    /^[ \t]/ { next }
    /^$/ { flush(); next }
    {
        i = index($0, ": ")
        if (i == 0) { name = $0; sub(/:$/, "", name); value = "" }
        else { name = substr($0, 1, i - 1); value = substr($0, i + 2) }
        if (name == "Package") pkg = value
        else if (name == "Version") ver = value
        else if (name == "Frostyard-Inputs") inputs = value
    }
    END { flush() }
' "$packages" >"$stanzas"

# Markdown cell: code-style a value, leave "none" plain.
cell() {
    local tick='`'
    if [[ "$1" == none ]]; then printf 'none'; else printf '%s%s%s' "$tick" "$1" "$tick"; fi
}

publish=()
rows=()
for app in "${apps[@]}"; do
    digest="$(app_inputs "$app")"
    newest="" newest_inputs=""
    while IFS=$'\t' read -r _ version inputs; do
        if [[ -z "$newest" ]] || dpkg --compare-versions "$version" gt "$newest"; then
            newest="$version" newest_inputs="$inputs"
        fi
    done < <(awk -F'\t' -v a="$app" '$1 == a' "$stanzas")

    if [[ "$app" == "$rebuild" ]]; then
        decision=forced
    elif [[ -z "$newest" || -z "$newest_inputs" || "$newest_inputs" != "$digest" ]]; then
        decision=changed
    else
        decision=unchanged
    fi

    printf '%s %s inputs=%s newest=%s newest-inputs=%s\n' \
        "$app" "$decision" "$digest" "${newest:-none}" "${newest_inputs:-none}" >&2
    rows+=("$(printf '%s|%s|%s|%s|%s' \
        "$app" "$decision" "${digest:-none}" "${newest:-none}" "${newest_inputs:-none}")")
    [[ "$decision" == unchanged ]] || publish+=("$app")
done

if ((${#publish[@]} == 0)); then
    printf '[]\n'
else
    printf '%s\n' "${publish[@]}" | jq -R . | jq -cs 'sort'
fi

if [[ -n "$summary" ]]; then
    {
        printf '\n### Which apps this run publishes\n\n'
        printf '| App | Decision | Inputs | Newest published | Newest inputs |\n'
        printf '|---|---|---|---|---|\n'
        for row in "${rows[@]}"; do
            IFS='|' read -r r_app r_decision r_digest r_newest r_field <<<"$row"
            printf '| %s | %s | %s | %s | %s |\n' \
                "$r_app" "$r_decision" "$(cell "$r_digest")" \
                "$(cell "$r_newest")" "$(cell "$r_field")"
        done
    } >>"$summary"
fi
