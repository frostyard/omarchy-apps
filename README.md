# omarchy-apps

Debian packages for the Omarchy ecosystem's in-house applications, built
from pinned, verified upstream sources and published to the
[frostyard APT repository](https://repository.frostyard.org). Consumed by
[frostyard/snosi](https://github.com/frostyard/snosi), whose sysexts need
these packages inside the immutable image: `mkosi.images/voxtype/mkosi.conf`
takes `Packages=voxtype` and `mkosi.images/moonlight/mkosi.conf` takes
`Packages=moonlight-qt`.

The repository built 10 more Omarchy apps for snosi's flurry desktop
(aether, cliamp, gpu-screen-recorder, herdr, hyprland-preview-share-picker,
omacalc, omacut, omawrite, tensaku, ttfx). snosi removed flurry
(frostyard/snosi#908, 2026-08-31), and on 2026-11-02 those 10 left the
build because no Frostyard image or sysext uses them
([core ADR-0066](https://github.com/frostyard/core/blob/main/docs/adr/0066-build-only-the-omarchy-apps-packages-that-snosi-uses.md)).
Their recipes stay in git history; their published versions stay in the
APT repository until a separate decision withdraws them.

Same shape as [frostyard/bootc-debian](https://github.com/frostyard/bootc-debian):
one build script per package, run in a `debian:trixie` container. Each push
to `main` builds every package, attaches them to a GitHub release, and asks
[frostyard/apt-publisher](https://github.com/frostyard/apt-publisher) to
publish that release to `https://repository.frostyard.org/debian/` (`trixie`).
This repository holds no signing key and no bucket credentials.

## Packages

| Package | Upstream | What it is |
|---|---|---|
| voxtype | [peteonrails/voxtype](https://github.com/peteonrails/voxtype) (prebuilt binary, AVX2) | AI dictation for the snosi `voxtype` sysext |
| moonlight-qt | [moonlight-stream/moonlight-qt](https://github.com/moonlight-stream/moonlight-qt) (AppImage repack) | Game-streaming client for the snosi `moonlight` sysext (pairs with the sunshine sysext) |

## Building locally

```bash
podman run --rm -v "$PWD":/src -w /src debian:trixie bash build.sh voxtype
```

Output lands in `dist/`. Every source is pinned in
`download/checksums.json` (sha256-verified tarballs and binaries).
`check-dependencies.yml` proposes weekly bump
PRs; CI must be green across the whole matrix before merging one.
Because `GITHUB_TOKEN` cannot trigger `pull_request` runs, the workflow
dispatches `build.yml` on the bump branch itself.

## Conventions

- Versions carry a `-frostyard<timestamp>` suffix so rebuilds of the same
  upstream version still sort newer in apt.
- Runtime `Depends` are computed with `dpkg-shlibdeps`, plus per-app extras
  for anything dlopen'd (runtime-probed libraries are deliberately NOT
  dependencies).
- voxtype ships upstream's AVX2 binary: x86-64-v3 CPU floor, the same
  baseline the Omarchy Arch package accepts.
