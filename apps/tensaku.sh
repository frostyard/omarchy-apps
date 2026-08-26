# tensaku: image annotator (Rust). omarchy's default screenshot editor
# (SCREENSHOT_EDITOR=tensaku-edit) and clipboard-image opener.
APP_DESC="Image annotator (Omarchy's screenshot editor)"
APP_EXTRA_DEPENDS=""
APP_SMOKE="tensaku --version || tensaku --help"
app_deps() { rust_deps; apt-get install --no-install-recommends --yes pkg-config libfontconfig-dev libepoxy-dev libgtk-4-dev libgtk4-layer-shell-dev libadwaita-1-dev; }
app_build() {
    verified_download tensaku "$WORK/src.tar.gz"
    mkdir -p "$WORK/src" && tar -xzf "$WORK/src.tar.gz" -C "$WORK/src" --strip-components=1
    (cd "$WORK/src" && cargo build --release --locked)
    local b
    for b in "$WORK/src/target/release/"*; do
        [[ -f "$b" && -x "$b" ]] && file -b "$b" | grep -q 'ELF' && install -D -m 0755 "$b" "$STAGE/usr/bin/$(basename "$b")"
    done
    true
}
