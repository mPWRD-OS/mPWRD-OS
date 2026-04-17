# Code Review Status

Date: 2026-04-17

Scope: static review of the current worktree, with focus on `customize-image.sh`, Armbian extension hooks, overlay files, and the repo's shell-based regression checks.

## Status

No outstanding static review findings were identified in the current worktree.

The previously reported regressions from the extension split are addressed in the current tree:

- OBS repository bootstrap is now centralized in `extensions/obs-bootstrap.sh`.
- `extensions/meshtasticd.sh` and `extensions/mpwrd-os-pkgs.sh` use HTTPS, `/etc/apt/keyrings`, and `signed-by=` source entries.
- Meshtastic package installation and board-specific Meshtastic configuration now run from real `post_family_tweaks__...` hooks in `extensions/meshtasticd.sh`.
- The Meshtastic install hook refreshes apt metadata inside the chroot before installing `meshtasticd` and `i2c-tools`.
- The regression script now validates extension-generated OBS source files and the Meshtastic hook lifecycle instead of checking stale `customize-image.sh` logic.
- `resolute` targets the published `xUbuntu_26.04` mPWRD OBS repository.
- Extension scripts that previously failed `shellcheck` with `SC2148` now declare Bash explicitly.

## Redundancy Review

The most important redundant command sequence was the duplicated OBS onboarding flow in:

- `extensions/meshtasticd.sh`
- `extensions/mpwrd-os-pkgs.sh`

That duplication has been removed by moving the shared signed-repository bootstrap into `extensions/obs-bootstrap.sh`.

Some duplication remains, but it is lower risk and currently acceptable:

- `extensions/meshtasticd.sh` still has parallel helper functions for `user_overlays` and `overlays`.
- `extensions/meshtasticd.sh` still repeats the per-board pattern of setting `MACAddressSource` and downloading a board-specific Meshtastic config fragment.

## Verification Performed

Verified directly in this review session:

- `bash tests/code-review-regressions.sh`

Previously verified and still reflected in the current tree:

- `bash -n customize-image.sh extensions/performance/*.sh extensions/quality/*.sh extensions/*.sh extensions/provisioning/*.sh tests/code-review-regressions.sh`
- `shellcheck extensions/meshtasticd.sh tests/code-review-regressions.sh`

All of the above completed without reported errors.

Additional dynamic signal:

- Full image build completed successfully after the Meshtastic hook fix.

## Residual Risk

This review now has a successful full-build signal, but it still does not include target-hardware boot validation.

The highest-value dynamic checks that remain are:

- Boot at least one RK3506 image and one RV1106 or RV1103 image on target hardware.
- Confirm the Meshtastic and mPWRD repositories install cleanly on supported Debian and Ubuntu releases with repo-scoped trust and without transport downgrades.
- Inspect the resulting `/boot/armbianEnv.txt` contents after customization on representative boards.
- Confirm Meshtastic config files and downloaded board-specific config fragments exist with the expected ownership on the built image.
- Validate boot ordering for deterministic MAC setup, rfkill unblock, NetworkManager, systemd-networkd, Bluetooth, and Wi-Fi provisioning on hardware.
