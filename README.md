# omarchy-apps

Debian packages for the Omarchy ecosystem's in-house applications, built
from pinned, verified upstream sources and published to the
[frostyard APT repository](https://repository.frostyard.org). Consumed by
[frostyard/snosi](https://github.com/frostyard/snosi)'s **flurry** desktop
(the Omarchy replica), where the atomic/immutable model means these must
ship *in the image* — Omarchy's `omarchy-pkg-add` flow has nothing to
install from on Debian, so flurry bakes the full set in.

Same shape as [frostyard/bootc-debian](https://github.com/frostyard/bootc-debian):
one build script per package, run in a `debian:trixie` container, publishing
via `frostyard/repogen`.

## Packages

| Package | Upstream | What it is / where Omarchy uses it |
|---|---|---|
| ttfx | [omacom-io/ttfx](https://github.com/omacom-io/ttfx) (Rust) | Terminal text effects — the `omarchy-screensaver` renderer |
| herdr | [omacom-io/herdr](https://github.com/omacom-io/herdr) (Rust) | Coding-agent runtime/terminal herder — `SUPER+CTRL+RETURN` |
| tensaku | [jondkinney/tensaku](https://github.com/jondkinney/tensaku) (Rust) | Image annotator — default screenshot editor (`tensaku-edit`) |
| hyprland-preview-share-picker | [WhySoBad/hyprland-preview-share-picker](https://github.com/WhySoBad/hyprland-preview-share-picker) (Rust) | Screen-share picker xdph is configured to use |
| cliamp | [bjarneo/cliamp](https://github.com/bjarneo/cliamp) (Go) | Winamp-style music TUI — `SUPER+SHIFT+ALT+M` |
| aether | [bjarneo/aether](https://github.com/bjarneo/aether) (Go) | Theming toolkit with native Omarchy support |
| voxtype | [peteonrails/voxtype](https://github.com/peteonrails/voxtype) (prebuilt binary, AVX2) | AI dictation — `voxtype record` bindings |
| omacalc | [omacom-io/omacalc](https://github.com/omacom-io/omacalc) (Qt6/QML) | Calculator — `SUPER+CTRL+Q` / XF86Calculator |
| omacut | [omacom-io/omacut](https://github.com/omacom-io/omacut) (Qt6/QML) | Video trimmer |
| omawrite | [omacom-io/omawrite](https://github.com/omacom-io/omawrite) (Qt6/QML) | Distraction-free writer — `SUPER+SHIFT+W` |
| moonlight-qt | [moonlight-stream/moonlight-qt](https://github.com/moonlight-stream/moonlight-qt) (AppImage repack) | Game-streaming client — pairs with the sunshine sysext |
| gpu-screen-recorder | [dec05eba](https://git.dec05eba.com/gpu-screen-recorder/about/) (C) | Screen recording (VAAPI/NVENC) — the whole Omarchy capture menu |

## Building locally

```bash
podman run --rm -v "$PWD":/src -w /src debian:trixie bash build.sh ttfx
```

Output lands in `dist/`. Every source is pinned in
`download/checksums.json` (sha256-verified tarballs/binaries; a
commit-verified git tag for gpu-screen-recorder, whose cgit host sits
behind a bot-check wall). `check-dependencies.yml` proposes weekly bump
PRs; CI must be green across the whole matrix before merging one.

## Conventions

- Versions carry a `-frostyard<timestamp>` suffix so rebuilds of the same
  upstream version still sort newer in apt.
- Runtime `Depends` are computed with `dpkg-shlibdeps`, plus per-app extras
  for anything dlopen'd (QML plugin modules, NVENC/CUDA are runtime-probed
  and deliberately NOT dependencies).
- `gsr-kms-server` gets `cap_sys_admin` via postinst `setcap` (dpkg does
  not preserve file capabilities).
- voxtype ships upstream's AVX2 binary: x86-64-v3 CPU floor, the same
  baseline the Omarchy Arch package accepts.
