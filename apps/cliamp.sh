# cliamp: retro Winamp-style terminal music player (Go, bjarneo).
# omarchy's SUPER+SHIFT+ALT+M "Music TUI".
APP_DESC="Retro terminal music player (Winamp-style TUI)"
APP_EXTRA_DEPENDS=""
APP_SMOKE="cliamp --version || cliamp --help"
app_deps() { go_deps; apt-get install --no-install-recommends --yes libasound2-dev pkg-config libflac-dev libvorbis-dev libogg-dev libopus-dev; }
app_build() {
    verified_download cliamp "$WORK/src.tar.gz"
    mkdir -p "$WORK/src" && tar -xzf "$WORK/src.tar.gz" -C "$WORK/src" --strip-components=1
    (cd "$WORK/src" && go build -trimpath -ldflags=-s -o "$WORK/cliamp" .)
    install -D -m 0755 "$WORK/cliamp" "$STAGE/usr/bin/cliamp"
}
