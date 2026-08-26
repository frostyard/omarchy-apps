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
    install -D -m 0755 "$WORK/src/target/release/tensaku" "$STAGE/usr/bin/tensaku"
    # tensaku-edit is a repo script, not a cargo binary -- it is the entry
    # point omarchy's screenshot editor flow execs (mirrors the upstream
    # Arch package()).
    install -D -m 0755 "$WORK/src/assets/tensaku-edit" "$STAGE/usr/bin/tensaku-edit"
    install -D -m 0644 "$WORK/src/dev.tensaku.Tensaku.desktop" "$STAGE/usr/share/applications/dev.tensaku.Tensaku.desktop"
    install -D -m 0644 "$WORK/src/assets/tensaku.svg" "$STAGE/usr/share/icons/hicolor/scalable/apps/dev.tensaku.Tensaku.svg"
}
