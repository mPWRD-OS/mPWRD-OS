# Code Review Status

Date: 2026-04-17

Scope: static review of the current worktree, with focus on `customize-image.sh`, Armbian extension hooks, overlay files, and the repo's shell-based regression checks.

## Status

No outstanding static review findings were identified in the current worktree.

The previously reported regressions from the extension split are addressed in the current tree:

- OBS repository bootstrap is now centralized in `extensions/obs-bootstrap.sh`.
- `extensions/meshtasticd.sh` and `extensions/mpwrd-os-pkgs.sh` now use HTTPS, `/etc/apt/keyrings`, and `signed-by=` source entries again.
- The regression script now validates extension-generated OBS source files instead of checking stale `customize-image.sh` logic.
- `resolute` now targets the published `xUbuntu_26.04` mPWRD OBS repository.
- Extension scripts that previously failed `shellcheck` with `SC2148` now declare Bash explicitly.

## Redundancy Review

The most important redundant command sequence was the duplicated OBS onboarding flow in:

- `extensions/meshtasticd.sh`
- `extensions/mpwrd-os-pkgs.sh`

That duplication has been removed by moving the shared signed-repository bootstrap into `extensions/obs-bootstrap.sh`.

Some duplication remains, but it is lower risk and currently acceptable:

- `customize-image.sh` still has parallel overlay writers for `user_overlays` and `overlays`.
- `customize-image.sh` still repeats the per-board pattern of setting `MACAddressSource` and downloading a board-specific Meshtastic config fragment.

## Verification Performed

- `bash -n customize-image.sh extensions/performance/*.sh extensions/quality/*.sh extensions/*.sh extensions/provisioning/*.sh tests/code-review-regressions.sh`
- `bash tests/code-review-regressions.sh`
- `shellcheck customize-image.sh extensions/performance/*.sh extensions/quality/*.sh extensions/*.sh extensions/provisioning/*.sh tests/code-review-regressions.sh`

All of the above completed without reported errors.

## Residual Risk

This review still did not include a full Armbian image build or target-hardware boot test.

The highest-value dynamic checks remain:

- Build at least one RK3506 image and one RV1106 or RV1103 image.
- Confirm the Meshtastic and mPWRD repositories install cleanly on supported Debian and Ubuntu releases with repo-scoped trust and without transport downgrades.
- Inspect the resulting `/boot/armbianEnv.txt` contents after customization on representative boards.
- Confirm Meshtastic config files and downloaded board-specific config fragments exist with the expected ownership.
- Validate boot ordering for deterministic MAC setup, rfkill unblock, NetworkManager, systemd-networkd, Bluetooth, and Wi-Fi provisioning on target hardware.
