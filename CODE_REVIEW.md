# Code Review Status

Date: 2026-04-16

Scope: review of the current staged worktree, with focus on the shell scripts, Armbian extension hooks, overlay files, and the new regression check added after the 2026-04-15 review.

## Status

No outstanding static review findings were identified in the reviewed worktree.

The issues called out in the 2026-04-15 review appear to be addressed:

- `customize-image.sh` now runs with `set -euo pipefail`.
- OBS repository setup now uses HTTPS, `/etc/apt/keyrings`, and `signed-by=` source entries.
- `InstallAptPkg` no longer uses `--allow-unauthenticated`.
- `EnableUserDTOverlay` and `EnableKernelDTOverlay` now anchor matches against `user_overlays=` and `overlays=`.
- `MTSetMacSrc` now fails clearly when the Meshtastic config file or `MACAddressSource` key is missing, and it verifies the replacement succeeded.
- `extensions/quality/fixed-eth-mac.sh` now orders the generated service before both `NetworkManager.service` and `systemd-networkd.service`.
- `extensions/unblock-rfkill.sh` no longer runs after `multi-user.target` and now hooks into `network-pre.target`.
- `overlay/fs/etc/update-motd.d/42-mpwrd-commands` now advertises `mpwrd-menu`.
- `extensions/performance/perf-tmp-rootfs.sh` now documents the `/opt/tmp` to `/tmp` bind mount correctly.
- `tests/code-review-regressions.sh` adds coverage for the previously reported regressions.

## Verification Performed

- `git diff --cached --check`
- `bash -n customize-image.sh extensions/performance/*.sh extensions/quality/*.sh extensions/*.sh tests/code-review-regressions.sh`
- `bash tests/code-review-regressions.sh`
- `shellcheck customize-image.sh extensions/performance/*.sh extensions/quality/*.sh extensions/*.sh tests/code-review-regressions.sh`

All of the above completed without reported errors.

## Residual Risk

This review still did not include a full Armbian image build or target-hardware boot test.

The highest-value dynamic checks remain:

- Build at least one RK3506 image and one RV1106 or RV1103 image.
- Confirm the Meshtastic and mPWRD repositories install cleanly on the supported Debian and Ubuntu releases without trust bypasses.
- Inspect the resulting `/boot/armbianEnv.txt` contents after customization on representative boards.
- Confirm Meshtastic config files and downloaded board-specific config fragments exist with the expected ownership.
- Validate boot ordering for deterministic MAC setup, rfkill unblock, NetworkManager, systemd-networkd, Bluetooth, and Wi-Fi provisioning on target hardware.
