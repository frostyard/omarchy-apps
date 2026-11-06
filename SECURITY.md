# Security policy

`omarchy-apps` builds Debian packages for the Omarchy ecosystem and publishes them through frostyard/apt-publisher. It holds no signing key or APT bucket credential.

## Reporting a vulnerability

Use [GitHub private vulnerability reporting](https://github.com/frostyard/omarchy-apps/security) to report a vulnerability privately.

Give the package name, the installed version, the package source and a minimal reproduction. Do not include signing material or publication credentials.

## Supported versions

The repository has no versioned releases. Fixes apply to the newest published package of each app: `voxtype` and `moonlight-qt`. Older versions leave the apt index as apt-publisher keeps the newest 2 versions of each app.

Package bugs must be reported to the upstream project or to this repository when the Frostyard packaging changed them.
