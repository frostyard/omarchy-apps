# ttfx: terminal text effects, single static-ish binary (Rust).
# omarchy-screensaver's renderer.
APP_DESC="Terminal text effects (Rust port of terminaltexteffects)"
APP_EXTRA_DEPENDS=""
APP_SMOKE="ttfx --version"
app_deps() { rust_deps; }
app_build() {
    verified_download ttfx "$WORK/src.tar.gz"
    mkdir -p "$WORK/src" && tar -xzf "$WORK/src.tar.gz" -C "$WORK/src" --strip-components=1
    (cd "$WORK/src" && cargo build --release --locked)
    install -D -m 0755 "$WORK/src/target/release/ttfx" "$STAGE/usr/bin/ttfx"
}
