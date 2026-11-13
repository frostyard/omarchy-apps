#!/bin/bash
# Decide which apps a run publishes, from the published Packages indexes.
#
# Usage: plan.sh --packages FILE [--packages FILE ...] [--rebuild APP] [--summary FILE]
#
#   --packages FILE  a Debian Packages index (the published main amd64 ones:
#                    1 for each codename apt-publisher serves). Repeat it once
#                    per index: every given index is read and compared.
#   --rebuild APP    also publish APP, whether or not its inputs changed
#                    (empty or absent: no app is forced)
#   --summary FILE   append a Markdown table of the decision, for
#                    $GITHUB_STEP_SUMMARY
#
# stdout: one JSON array, compact and sorted, of the apps to publish
#         (changed + forced).
# stderr: one line per app:
#         APP DECISION inputs=<digest> newest=<version or none> newest-inputs=<field or none>
#         with more than 1 --packages, the line ends with
#         changed-in=<index file names, comma separated, or none>.
#
# An app is unchanged in 1 index when the Frostyard-Inputs field of its newest
# published version in that index equals the digest of its inputs
# (lib/inputs.sh). No published version, no field, or another value: changed in
# that index. An app is changed when it is changed in any of the given indexes,
# and unchanged only when it is unchanged in every one: apt-publisher publishes
# the same unmarked .deb files to every codename, so a missing or stale copy in
# 1 index must publish again (frostyard/core ADR-0055). The newest, newest-inputs
# and stderr fields come from the first index that is changed, or from the first
# index when the app is unchanged in all of them. The summary table names every
# index in which the app is changed. Newest is chosen with dpkg
# --compare-versions, not sort -V.
set -euo pipefail

SRCDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/inputs.sh
source "$SRCDIR/lib/inputs.sh"

usage() { echo "usage: plan.sh --packages FILE [--packages FILE ...] [--rebuild APP] [--summary FILE]" >&2; exit 2; }

packages=() rebuild="" summary=""
while (($# > 0)); do
    case "$1" in
        --packages) (($# >= 2)) || usage; packages+=("$2"); shift 2 ;;
        --rebuild) (($# >= 2)) || usage; rebuild="$2"; shift 2 ;;
        --summary) (($# >= 2)) || usage; summary="$2"; shift 2 ;;
        -h | --help) usage ;;
        *) echo "unknown argument: $1" >&2; usage ;;
    esac
done

((${#packages[@]} > 0)) || usage
for f in "${packages[@]}"; do
    [[ -f "$f" ]] || { echo "no such Packages file: $f" >&2; exit 1; }
done

# label FILE: how 1 index is named in the summary table. apt-publisher's index
# files carry the codename in their name, so the name identifies the index.
labels=()
for f in "${packages[@]}"; do
    labels+=("$(basename "$f")")
done

apps=()
for f in "$SRCDIR"/apps/*.sh; do
    [[ -f "$f" ]] || continue
    apps+=("$(basename "$f" .sh)")
done
((${#apps[@]} > 0)) || { echo "no apps in $SRCDIR/apps" >&2; exit 1; }
mapfile -t apps < <(printf '%s\n' "${apps[@]}" | LC_ALL=C sort)

# --rebuild names exactly one app, or nothing.
if [[ -n "$rebuild" ]]; then
    found=0
    for app in "${apps[@]}"; do
        [[ "$app" == "$rebuild" ]] && found=1
    done
    ((found)) || { echo "unknown app for --rebuild: $rebuild" >&2; exit 1; }
fi

# Package<TAB>Version<TAB>Frostyard-Inputs for every stanza of 1 index, in a
# temporary file per index. Multi-line field continuations start with a space
# and carry nothing we need.
tables=()
trap 'rm -f "${tables[@]}"' EXIT
for f in "${packages[@]}"; do
    table="$(mktemp)"
    tables+=("$table")
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
    ' "$f" >"$table"
done

# Markdown cell: code-style a value, leave "none" plain.
cell() {
    local tick='`'
    if [[ "$1" == none ]]; then printf 'none'; else printf '%s%s%s' "$tick" "$1" "$tick"; fi
}

publish=()
rows=()
for app in "${apps[@]}"; do
    digest="$(app_inputs "$app")"
    # The newest published version and its field in each index, and the indexes
    # in which the app is changed.
    index_newest=() index_field=() changed_in=()
    for i in "${!packages[@]}"; do
        newest="" field=""
        while IFS=$'\t' read -r _ version inputs; do
            if [[ -z "$newest" ]] || dpkg --compare-versions "$version" gt "$newest"; then
                newest="$version" field="$inputs"
            fi
        done < <(awk -F'\t' -v a="$app" '$1 == a' "${tables[i]}")
        index_newest+=("$newest") index_field+=("$field")
        if [[ -z "$newest" || -z "$field" || "$field" != "$digest" ]]; then
            changed_in+=("$i")
        fi
    done

    if [[ "$app" == "$rebuild" ]]; then
        decision=forced
    elif ((${#changed_in[@]} > 0)); then
        decision=changed
    else
        decision=unchanged
    fi

    # The first index that is changed decides the fields; unchanged in every
    # index, the first index does.
    show=0
    ((${#changed_in[@]} == 0)) || show="${changed_in[0]}"
    newest="${index_newest[show]}" newest_inputs="${index_field[show]}"
    changed_field=none
    if ((${#changed_in[@]} > 0)); then
        changed_labels=()
        for i in "${changed_in[@]}"; do changed_labels+=("${labels[i]}"); done
        changed_field="$(printf '%s\n' "${changed_labels[@]}" | paste -sd, -)"
    fi

    if ((${#packages[@]} > 1)); then
        printf '%s %s inputs=%s newest=%s newest-inputs=%s changed-in=%s\n' \
            "$app" "$decision" "$digest" "${newest:-none}" "${newest_inputs:-none}" "$changed_field" >&2
    else
        printf '%s %s inputs=%s newest=%s newest-inputs=%s\n' \
            "$app" "$decision" "$digest" "${newest:-none}" "${newest_inputs:-none}" >&2
    fi
    rows+=("$(printf '%s|%s|%s|%s|%s|%s' \
        "$app" "$decision" "${digest:-none}" "${newest:-none}" "${newest_inputs:-none}" "$changed_field")")
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
        printf '| App | Decision | Inputs | Newest published | Newest inputs | Changed in |\n'
        printf '|---|---|---|---|---|---|\n'
        for row in "${rows[@]}"; do
            IFS='|' read -r r_app r_decision r_digest r_newest r_field r_changed <<<"$row"
            printf '| %s | %s | %s | %s | %s | %s |\n' \
                "$r_app" "$r_decision" "$(cell "$r_digest")" \
                "$(cell "$r_newest")" "$(cell "$r_field")" "$(cell "$r_changed")"
        done
    } >>"$summary"
fi
