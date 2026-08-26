# voxtype: AI dictation (whisper-based). Upstream ships prebuilt binaries
# only; we repackage the avx2 variant (x86-64-v3 floor -- same baseline the
# omarchy AUR package accepts).
APP_DESC="AI voice dictation for Wayland (prebuilt upstream binary, AVX2)"
APP_EXTRA_DEPENDS=""
APP_SMOKE="voxtype --version || voxtype --help"
app_deps() { :; }
app_build() {
    verified_download voxtype "$WORK/voxtype"
    install -D -m 0755 "$WORK/voxtype" "$STAGE/usr/bin/voxtype"
}
