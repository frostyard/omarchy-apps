# cliamp: retro Winamp-style terminal music player (Go, bjarneo).
# omarchy's SUPER+SHIFT+ALT+M "Music TUI".
APP_DESC="Retro terminal music player (Winamp-style TUI)"
APP_EXTRA_DEPENDS=""
# --version exists only when main.version is set at link time (urfave/cli
# hides the flag for an empty version), as upstream's AUR build does.
APP_SMOKE="cliamp --version"
# libmpg123-dev: cliamp 2.x links go-librespot's mp3 decoder through cgo
# (pkg-config libmpg123); upstream's README lists it with the other codec
# headers. dpkg-shlibdeps maps it to the libmpg123-0t64 runtime Depends.
app_deps() { go_deps; apt-get install --no-install-recommends --yes libasound2-dev pkg-config libflac-dev libvorbis-dev libogg-dev libopus-dev libmpg123-dev; }
app_build() {
    verified_download cliamp "$WORK/src.tar.gz"
    mkdir -p "$WORK/src" && tar -xzf "$WORK/src.tar.gz" -C "$WORK/src" --strip-components=1
    (cd "$WORK/src" && go build -trimpath -ldflags="-s -X main.version=v${VERSION}" -o "$WORK/cliamp" .)
    install -D -m 0755 "$WORK/cliamp" "$STAGE/usr/bin/cliamp"
}
