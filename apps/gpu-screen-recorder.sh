# gpu-screen-recorder (dec05eba, C/meson): omarchy's screen recording.
# GIT pin (commit-verified) -- the cgit host is behind an Anubis bot-check
# wall, so no fetchable release tarball exists; see checksums.json.
# NVENC/CUDA are dlopen'd at runtime (no build-time NVIDIA deps); VAAPI is
# the baseline path. gsr-kms-server needs cap_sys_admin (KMS capture) --
# granted via postinst setcap, dpkg does not preserve file capabilities.
APP_DESC="Screen recorder with GPU-accelerated VAAPI/NVENC encoding"
APP_EXTRA_DEPENDS="libcap2-bin"
APP_SMOKE="test -x /usr/bin/gpu-screen-recorder && test -x /usr/bin/gsr-kms-server && getcap /usr/bin/gsr-kms-server"
app_deps() {
    apt-get install --no-install-recommends --yes \
        meson ninja-build pkg-config \
        libavcodec-dev libavformat-dev libavutil-dev libswresample-dev libavfilter-dev \
        libgl-dev libegl-dev libx11-dev libxcomposite-dev libxrandr-dev \
        libxfixes-dev libxdamage-dev libxi-dev \
        libpulse-dev libva-dev libdrm-dev libcap-dev \
        libwayland-dev wayland-protocols libpipewire-0.3-dev libdbus-1-dev libjpeg62-turbo-dev libvulkan-dev
}
app_build() {
    local url tag commit
    url=$(jq -r '.["gpu-screen-recorder"].git' "$SRCDIR/download/checksums.json")
    tag=$(jq -r '.["gpu-screen-recorder"].tag' "$SRCDIR/download/checksums.json")
    commit=$(jq -r '.["gpu-screen-recorder"].commit' "$SRCDIR/download/checksums.json")
    git clone --depth 1 --branch "$tag" "$url" "$WORK/src"
    local head
    head=$(git -C "$WORK/src" rev-parse HEAD)
    [[ "$head" == "$commit" ]] || { echo "gpu-screen-recorder: tag $tag resolved to $head, pinned $commit -- refusing" >&2; exit 1; }
    (cd "$WORK/src" && meson setup build -Dsystemd=true -Dffmpeg_static=false -Dstrip=true --buildtype=release --prefix=/usr && meson compile -C build && DESTDIR="$STAGE" meson install -C build)
    mkdir -p "$STAGE/DEBIAN"
    cat >"$STAGE/DEBIAN/postinst" <<'POST'
#!/bin/sh
set -e
setcap cap_sys_admin+ep /usr/bin/gsr-kms-server || true
POST
    chmod 755 "$STAGE/DEBIAN/postinst"
}
