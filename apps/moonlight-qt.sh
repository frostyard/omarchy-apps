# shellcheck shell=bash disable=SC2034  # sourced by build.sh and smoke.sh: APP_* are read there
# moonlight-qt: game-streaming client (pairs with the sunshine host).
# Upstream publishes NO amd64 debs (its Cloudsmith apt repo carries arm64
# only, verified 2026-08-26) and is not in Debian; the canonical x86_64
# Linux artifact is the AppImage, which bundles its Qt runtime. We repack the
# extracted AppImage under /usr/lib/moonlight-qt.
#
# The repack is NOT self-contained: the AppImage payload links the host's X11,
# OpenGL, VA-API, font and Kerberos libraries, and it bundles only the xcb Qt
# platform plugin, so it needs a running X server as well. dpkg-shlibdeps
# yields no Depends for the payload (the published 6.2.0 package had none at
# all), so APP_EXTRA_DEPENDS names those libraries itself. They are the
# complete set of `ldd ... not found` results measured over every ELF file in
# the payload on Debian 13 and Debian 14; the same names exist in both
# codenames. Add a name here when the payload links a new library, and check it
# in the smoke-forky job as well.
APP_DESC="Moonlight game-streaming client (repacked upstream AppImage)"
APP_EXTRA_DEPENDS="libx11-6, libva2, libva-x11-2, libva-drm2, libgl1, libegl1, libdrm2, libfontconfig1, libopengl0, libharfbuzz0b, libfreetype6, libcom-err2, libgpg-error0, libsm6, libice6"
# Only the xcb Qt platform plugin is bundled, so `--version` still needs an X
# display: xvfb-run starts one. xvfb and xauth are test-only packages, not
# Depends of the package.
APP_SMOKE="xvfb-run -a moonlight-qt --version"
APP_SMOKE_DEPS="xvfb xauth"
app_deps() { :; }
app_build() {
    verified_download moonlight-qt "$WORK/moonlight.AppImage"
    chmod +x "$WORK/moonlight.AppImage"
    # --appimage-extract works without FUSE (static squashfs extraction).
    (cd "$WORK" && ./moonlight.AppImage --appimage-extract >/dev/null)
    mkdir -p "$STAGE/usr/lib"
    cp -a "$WORK/squashfs-root" "$STAGE/usr/lib/moonlight-qt"
    mkdir -p "$STAGE/usr/bin"
    cat >"$STAGE/usr/bin/moonlight-qt" <<'WRAP'
#!/bin/sh
exec /usr/lib/moonlight-qt/AppRun "$@"
WRAP
    chmod 755 "$STAGE/usr/bin/moonlight-qt"
    local desk
    desk=$(find "$WORK/squashfs-root" -maxdepth 1 -name '*.desktop' | head -1)
    if [[ -n "$desk" ]]; then
        sed 's|^Exec=.*|Exec=/usr/bin/moonlight-qt %u|' "$desk" \
            > "$STAGE/usr/share/applications/com.moonlight_stream.Moonlight.desktop.tmp" 2>/dev/null || true
        mkdir -p "$STAGE/usr/share/applications"
        sed 's|^Exec=.*|Exec=/usr/bin/moonlight-qt %u|' "$desk" \
            > "$STAGE/usr/share/applications/com.moonlight_stream.Moonlight.desktop"
        rm -f "$STAGE/usr/share/applications/com.moonlight_stream.Moonlight.desktop.tmp"
    fi
    local icon
    icon=$(find "$WORK/squashfs-root" -maxdepth 1 \( -name '*.png' -o -name '*.svg' \) | head -1)
    [[ -n "$icon" ]] && install -D -m 0644 "$icon" \
        "$STAGE/usr/share/icons/hicolor/256x256/apps/moonlight.png"
    true
}
