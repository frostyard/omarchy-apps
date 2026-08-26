# hyprland-preview-share-picker (Rust): xdg-desktop-portal-hyprland names it
# as custom_picker_binary in omarchy's xdph.conf.
# GIT pin (commit-verified): the release tarball omits the
# lib/hyprland-protocols git submodule the build requires, and its build.rs
# derives the version string from `git describe`, so a real clone at the
# pinned tag is the only faithful source. Submodule content is pinned
# transitively by the superproject commit's gitlinks.
APP_DESC="Screen-share picker with live previews for Hyprland"
APP_EXTRA_DEPENDS=""
APP_SMOKE="hyprland-preview-share-picker --help"
app_deps() {
    rust_deps
    apt-get install --no-install-recommends --yes \
        libgtk-4-dev libgtk4-layer-shell-dev libwayland-dev
}
app_build() {
    local url tag commit
    url=$(jq -r '.["hyprland-preview-share-picker"].git' "$SRCDIR/download/checksums.json")
    tag=$(jq -r '.["hyprland-preview-share-picker"].tag' "$SRCDIR/download/checksums.json")
    commit=$(jq -r '.["hyprland-preview-share-picker"].commit' "$SRCDIR/download/checksums.json")
    git clone --depth 1 --branch "$tag" --recurse-submodules --shallow-submodules "$url" "$WORK/src"
    local head
    head=$(git -C "$WORK/src" rev-parse HEAD)
    [[ "$head" == "$commit" ]] || { echo "share-picker: tag $tag resolved to $head, pinned $commit -- refusing" >&2; exit 1; }
    (cd "$WORK/src" && cargo build --release --locked)
    install -D -m 0755 "$WORK/src/target/release/hyprland-preview-share-picker" \
        "$STAGE/usr/bin/hyprland-preview-share-picker"
}
