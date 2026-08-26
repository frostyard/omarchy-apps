# omacalc: Omarchy's calculator (Qt6/QML, omacom-io). Bound to
# SUPER+CTRL+Q and the XF86Calculator hardware key.
APP_DESC="Simple calculator (Omarchy, Qt6/QML)"
# QML plugin modules are dlopen'd, invisible to shlibdeps.
APP_EXTRA_DEPENDS="qml6-module-qtquick-controls, qml6-module-qtquick-layouts, qml6-module-qtquick-window, qml6-module-qtqml-workerscript, qml6-module-qtquick-templates"
APP_SMOKE="test -x /usr/bin/omacalc"
app_deps() {
    apt-get install --no-install-recommends --yes \
        qt6-base-dev qt6-declarative-dev qmake6 qt6-base-dev-tools
}
app_build() {
    verified_download omacalc "$WORK/src.tar.gz"
    mkdir -p "$WORK/src" && tar -xzf "$WORK/src.tar.gz" -C "$WORK/src" --strip-components=1
    (cd "$WORK/src" && qmake6 && make -j"$(nproc)")
    install -D -m 0755 "$WORK/src/omacalc" "$STAGE/usr/bin/omacalc"
}
