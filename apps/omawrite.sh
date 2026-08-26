# omawrite: distraction-free writer (Qt6/QML, omacom-io). SUPER+SHIFT+W.
APP_DESC="The essence of writing (Omarchy, Qt6/QML)"
APP_EXTRA_DEPENDS="qml6-module-qtquick-controls, qml6-module-qtquick-layouts, qml6-module-qtquick-window, qml6-module-qtqml-workerscript, qml6-module-qtquick-templates, qml6-module-qtquick-dialogs"
APP_SMOKE="test -x /usr/bin/omawrite"
app_deps() {
    apt-get install --no-install-recommends --yes \
        qt6-base-dev qt6-declarative-dev qmake6 qt6-base-dev-tools
}
app_build() {
    verified_download omawrite "$WORK/src.tar.gz"
    mkdir -p "$WORK/src" && tar -xzf "$WORK/src.tar.gz" -C "$WORK/src" --strip-components=1
    (cd "$WORK/src" && qmake6 && make -j"$(nproc)")
    install -D -m 0755 "$WORK/src/omawrite" "$STAGE/usr/bin/omawrite"
}
