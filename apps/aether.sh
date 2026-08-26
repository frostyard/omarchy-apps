# aether: Omarchy theming toolkit (Go + wails/webkit GUI, bjarneo).
# The heaviest build in the set: wails compiles an embedded npm frontend
# (frontend/dist) and links against webkit2gtk. The wails CLI version is
# pinned to the version in aether's own go.mod; go module downloads are
# verified against the Go checksum database.
APP_DESC="Theming toolkit with native Omarchy support (wails GUI)"
APP_EXTRA_DEPENDS=""
APP_SMOKE="test -x /usr/bin/aether"
app_deps() {
    go_deps
    apt-get install --no-install-recommends --yes \
        pkg-config nodejs npm libwebkit2gtk-4.1-dev libgtk-3-dev
}
app_build() {
    verified_download aether "$WORK/src.tar.gz"
    mkdir -p "$WORK/src" && tar -xzf "$WORK/src.tar.gz" -C "$WORK/src" --strip-components=1
    local wails_version
    wails_version=$(grep -oE 'github.com/wailsapp/wails/v2 v[0-9.]+' "$WORK/src/go.mod" | awk '{print $2}')
    GOBIN=/usr/local/bin go install "github.com/wailsapp/wails/v2/cmd/wails@${wails_version}"
    (cd "$WORK/src" && wails build -tags webkit2_41)
    install -D -m 0755 "$WORK/src/build/bin/aether" "$STAGE/usr/bin/aether"
    [[ -f "$WORK/src/li.oever.aether.desktop" ]] &&
        install -D -m 0644 "$WORK/src/li.oever.aether.desktop" "$STAGE/usr/share/applications/li.oever.aether.desktop"
    [[ -f "$WORK/src/li.oever.aether.url-handler.desktop" ]] &&
        install -D -m 0644 "$WORK/src/li.oever.aether.url-handler.desktop" "$STAGE/usr/share/applications/li.oever.aether.url-handler.desktop"
    [[ -f "$WORK/src/assets/aether-icon-512.png" ]] &&
        install -D -m 0644 "$WORK/src/assets/aether-icon-512.png" "$STAGE/usr/share/icons/hicolor/512x512/apps/aether.png"
    true
}
