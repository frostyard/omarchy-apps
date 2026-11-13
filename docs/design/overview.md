# Omarchy applications packaging overview

Living document. Rationale: [core ADR-0067](https://github.com/frostyard/core/blob/main/docs/adr/0067-publish-omarchy-apps-on-change-and-keep-the-newest-two.md).

## Overview

`omarchy-apps` builds Debian 13 (`trixie`) packages for the Omarchy ecosystem from pinned upstream sources. The maintained packages are `voxtype` and `moonlight-qt`. They serve snosi sysexts: `mkosi.images/voxtype/mkosi.conf` uses `Packages=voxtype`, and `mkosi.images/moonlight/mkosi.conf` uses `Packages=moonlight-qt`.

One build produces 1 unmarked `.deb`, and the same file is published to Debian 13 (`trixie`) and Debian 14 (`forky`). A `~debNN` marker would restrict a package to 1 codename (core ADR-0055); none is used, so both codenames get the same bytes. The `trixie` build proves the package on Debian 13, and the `smoke-forky` job proves it installs and runs on Debian 14 before anything is released. omarchy-apps' registration for `forky` in apt-publisher's `config/producers.tsv` is the compatibility record.

The repository has the same build shape as `frostyard/bootc-debian`: one build script for one package, with each app in a separate recipe and a container build for the package. The repository built 10 more Omarchy applications for snosi's flurry desktop: `aether`, `cliamp`, `gpu-screen-recorder`, `herdr`, `hyprland-preview-share-picker`, `omacalc`, `omacut`, `omawrite`, `tensaku` and `ttfx`. snosi removed flurry in `frostyard/snosi#908` on 2026-08-31. Those 10 recipes left the build on 2026-11-02 because no Frostyard image or sysext used them. Core ADR-0066 records this rule. Their recipes remain in git history, and their published versions remain in the APT repository until a separate withdrawal decision.

## Packages

| Package | Upstream | What it is |
| --- | --- | --- |
| `voxtype` | [peteonrails/voxtype](https://github.com/peteonrails/voxtype) (prebuilt binary, AVX2) | AI dictation for the snosi `voxtype` sysext |
| `moonlight-qt` | [moonlight-stream/moonlight-qt](https://github.com/moonlight-stream/moonlight-qt) (AppImage repack) | Game-streaming client for the snosi `moonlight` sysext (pairs with the sunshine sysext) |

## Design

Each app has `apps/<name>.sh`, and the upstream pin has an entry in `download/checksums.json`. `build.sh` runs as root inside `debian:trixie`, installs build tools with `apt-get`, loads the app recipe and verified downloader, and writes `dist/<name>_<version>-frostyard<stamp>_<arch>.deb`.

The input digest covers 4 files and 1 pin: `build.sh`, `lib/deb.sh`, `download/verified-download.sh`, `apps/<app>.sh`, plus only that app's entry in `download/checksums.json`. The app entry includes URL, SHA-256 and version. `lib/inputs.sh` writes `sha256:<64 hex>`. `lib/deb.sh` stores this value in the package field `Frostyard-Inputs`.

On `main`, `plan.sh` reads 1 published Packages index for each codename and compares the newest published `Frostyard-Inputs` value in that index with the digest of the current tree. `dpkg --compare-versions` selects the newest published version. In 1 index, a missing package, missing field or different digest is changed. An app is changed when it is changed in any index, and unchanged only when every index holds its current digest, so an app that never reached `forky` publishes again. The plan rebuilds and publishes only changed or forced apps, and its summary table names each index in which an app is changed.

A pull request or a dispatch outside `main` builds every app. It does not publish. Leave `rebuild` empty for normal publication. Set `rebuild` to one app name in the Build workflow to force that app, whether or not its digest changed. This is useful after a Debian base or build package change that is not in the input digest.

The build container has a debian:trixie base and installs build dependencies with `apt-get`. These values are not part of the input digest. Runtime `Depends` come from `dpkg-shlibdeps`, plus per-app extras for libraries that the app loads with dlopen. Libraries that the app only probes at run time are deliberately NOT dependencies. The voxtype package uses the upstream AVX2 binary and sets an x86-64-v3 CPU floor, matching the Omarchy Arch package.

The build workflow validates the release assets, creates a timestamp tag and attaches exactly one `amd64` `.deb` for each published app. The `build` job installs that package in `debian:trixie` and runs the app's `APP_SMOKE`; the `smoke-forky` job installs the same artifact in `debian:forky` and runs the same smoke test there. The release needs both. The run then sends a `publish-deb` dispatch to frostyard/apt-publisher with codenames `trixie` and `forky`, and apt-publisher publishes the same unmarked file to each one. This repository has no signing key or APT bucket credential. apt-publisher keeps the newest 2 versions of each app. Older versions leave the index as new versions arrive; pool files stay.

## Operational notes

Versions use `-frostyard<timestamp>`, so repeated builds of the same upstream version sort newer. Each Monday, `check-dependencies.yml` updates the pinned URL, SHA-256 and version of every app with a newer upstream tag, in 1 PR on the branch `update-upstream-versions`. A bump of 1 app does not change the digest of another app. Because `GITHUB_TOKEN` cannot start `pull_request` workflows for the pull request it opens, the workflow dispatches `build.yml` and `ci.yml` on the bump branch. `ci` is the gate check, so the bump PR must run it too. CI must build every app before merge.

Local builds use Podman and the Debian 13 container:

```sh
podman run --rm -v "$PWD":/src -w /src debian:trixie bash build.sh voxtype
```

The package output is in `dist/`.

## Add an app

1. Confirm that a snosi image or sysext uses the package. Core ADR-0066 limits the maintained build set to these packages.
2. Add `apps/<name>.sh` with `APP_DESC`, `APP_EXTRA_DEPENDS`, `APP_SMOKE`, `app_deps()` and `app_build()`. The header of `build.sh` describes these fields and functions.
3. Add the upstream pin with `url`, `sha256` and `version` to `download/checksums.json`.
4. Add the upstream repository to the `REPOS` map in `.github/workflows/check-dependencies.yml`.
5. Add the package name to the omarchy-apps entry in frostyard/apt-publisher `config/producers.tsv`, or apt-publisher refuses the release. Merge that apt-publisher pull request first.
6. Open a pull request in this repository. It builds every app. The first `main` run publishes the new app.

## References

- Rationale: [ADR-0066](https://github.com/frostyard/core/blob/main/docs/adr/0066-build-only-the-omarchy-apps-packages-that-snosi-uses.md), [ADR-0067](https://github.com/frostyard/core/blob/main/docs/adr/0067-publish-omarchy-apps-on-change-and-keep-the-newest-two.md)
- Publication: [ADR-0055](https://github.com/frostyard/core/blob/main/docs/adr/0055-publish-debian-packages-through-the-apt-publisher.md), [ADR-0060](https://github.com/frostyard/core/blob/main/docs/adr/0060-publish-omarchy-apps-through-the-apt-publisher.md)
