# herdr: "the runtime your coding agents live on" (Rust, omacom-io).
# Bound to SUPER+CTRL+RETURN in omarchy; skel ships config.toml.
APP_DESC="Coding-agent runtime and terminal herder (Omarchy)"
APP_EXTRA_DEPENDS=""
APP_SMOKE="herdr --version || herdr --help"
app_deps() {
    rust_deps
    apt-get install --no-install-recommends --yes libssl-dev xz-utils
    # herdr's build.rs compiles the vendored libghostty-vt with zig
    # (minimum_zig_version 0.15.2 in its build.zig.zon); Debian ships no
    # zig, so install the pinned upstream toolchain.
    verified_download zig "$WORK/zig.tar.xz"
    mkdir -p /opt/zig && tar -xJf "$WORK/zig.tar.xz" -C /opt/zig --strip-components=1
    ln -sf /opt/zig/zig /usr/local/bin/zig
    zig version
}
app_build() {
    verified_download herdr "$WORK/src.tar.gz"
    mkdir -p "$WORK/src" && tar -xzf "$WORK/src.tar.gz" -C "$WORK/src" --strip-components=1
    (cd "$WORK/src" && cargo build --release --locked)
    install -D -m 0755 "$WORK/src/target/release/herdr" "$STAGE/usr/bin/herdr"
}
