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
one build script per package, run in a `debian:trixie` container. A push to
`main` builds and publishes only the packages whose inputs changed: it
attaches them to a GitHub release and asks
[frostyard/apt-publisher](https://github.com/frostyard/apt-publisher) to
publish that release to `https://repository.frostyard.org/debian/` (`trixie`).
This repository holds no signing key and no bucket credentials.

## What gets published

An app is published only when its inputs changed. The inputs of an app are:

- `build.sh`, `lib/deb.sh`, `download/verified-download.sh` and
  `apps/<app>.sh`;
- its own entry in `download/checksums.json` (url, sha256, version). That
  entry only: a bump of another app leaves this app alone.

`lib/inputs.sh` digests those into `sha256:<64 hex>`. `lib/deb.sh` writes the
digest into the package as the `Frostyard-Inputs` control field (`dpkg-deb`
accepts it as a user field, and aptly copies it into the `Packages` index),
and `plan.sh` compares that field on the newest published version with the
digest of the current tree, using `dpkg --compare-versions` to find the newest
version. No published version, no field, or another value means changed, so
every app is rebuilt once when this rule first lands.

Not inputs: the `debian:trixie` base image and the packages `apt-get` installs
during the build. After a Debian change that matters to a package, force a
rebuild of that app by hand:

1. Actions -> Build -> Run workflow, on `main`.
2. Set `rebuild` to the app name (`voxtype` or `moonlight-qt`).

That one app is rebuilt and published whatever its inputs say. Leave
`rebuild` empty for a normal run.

A pull request (and a dispatch on any other branch, such as the upstream bump
branch) builds every app, so the whole matrix is tested, and publishes
nothing.

apt-publisher keeps the newest 2 versions of each app in the index
([core ADR-0067](https://github.com/frostyard/core/blob/main/docs/adr/0067-publish-omarchy-apps-on-change-and-keep-the-newest-two.md));
older versions leave the index as new ones arrive. Their pool files stay.

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
`plan.sh --packages FILE` prints what a run on `main` would publish (one
`unchanged`/`changed`/`forced` line per app on stderr), and
`bash tests/run.sh` runs its tests; both need `jq` and `dpkg`, and no
network. `check-dependencies.yml` proposes weekly bump
PRs; CI must be green across the whole matrix before merging one.
Because `GITHUB_TOKEN` cannot trigger `pull_request` runs, the workflow
dispatches `build.yml` on the bump branch itself.

## Conventions

- Versions carry a `-frostyard<timestamp>` suffix so rebuilds of the same
  upstream version still sort newer in apt.
- Every package carries `Frostyard-Inputs`, the digest of what built it;
  only apps whose digest changed are published again.
- Runtime `Depends` are computed with `dpkg-shlibdeps`, plus per-app extras
  for anything dlopen'd (runtime-probed libraries are deliberately NOT
  dependencies).
- voxtype ships upstream's AVX2 binary: x86-64-v3 CPU floor, the same
  baseline the Omarchy Arch package accepts.
