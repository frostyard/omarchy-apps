# moonlight-qt: game-streaming client (pairs with the sunshine host).
# Upstream publishes NO amd64 debs (its Cloudsmith apt repo carries arm64
# only, verified 2026-08-26) and is not in Debian; the canonical x86_64
# Linux artifact is the AppImage, which bundles its whole Qt runtime. We
# repack the extracted AppImage under /usr/lib/moonlight-qt -- the result
# is self-contained, so shlibdeps sees only the base-system linkage of the
# AppRun stub.
APP_DESC="Moonlight game-streaming client (repacked upstream AppImage)"
APP_EXTRA_DEPENDS=""
APP_SMOKE="test -x /usr/bin/moonlight-qt"
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
