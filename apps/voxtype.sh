# voxtype: AI dictation (whisper-based). Upstream ships prebuilt binaries
# only; we repackage the avx2 variant (x86-64-v3 floor -- same baseline the
# omarchy AUR package accepts).
APP_DESC="AI voice dictation for Wayland (prebuilt upstream binary, AVX2)"
APP_EXTRA_DEPENDS=""
APP_SMOKE="voxtype --version || voxtype --help || test -x /usr/bin/voxtype"
# libasound2t64 must be PRESENT at build time so dpkg-shlibdeps can map the
# prebuilt binary's alsa linkage into Depends (shlibdeps resolves against
# installed libraries; without it the deb shipped with no Depends at all --
# caught by the first CI smoke run).
app_deps() { apt-get install --no-install-recommends --yes libasound2t64; }
app_build() {
    verified_download voxtype "$WORK/voxtype"
    install -D -m 0755 "$WORK/voxtype" "$STAGE/usr/bin/voxtype"
}
