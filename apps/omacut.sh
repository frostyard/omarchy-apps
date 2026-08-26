# omacut: video trimmer (Qt6/QML + multimedia, omacom-io).
APP_DESC="Cut a video to the right trim (Omarchy, Qt6/QML)"
APP_EXTRA_DEPENDS="qml6-module-qtquick-controls, qml6-module-qtquick-layouts, qml6-module-qtquick-window, qml6-module-qtqml-workerscript, qml6-module-qtquick-templates, qml6-module-qtmultimedia, libqt6multimedia6, ffmpeg"
APP_SMOKE="test -x /usr/bin/omacut"
app_deps() {
    apt-get install --no-install-recommends --yes \
        qt6-base-dev qt6-declarative-dev qt6-multimedia-dev qmake6 qt6-base-dev-tools
}
app_build() {
    verified_download omacut "$WORK/src.tar.gz"
    mkdir -p "$WORK/src" && tar -xzf "$WORK/src.tar.gz" -C "$WORK/src" --strip-components=1
    (cd "$WORK/src" && qmake6 && make -j"$(nproc)")
    install -D -m 0755 "$WORK/src/omacut" "$STAGE/usr/bin/omacut"
}
