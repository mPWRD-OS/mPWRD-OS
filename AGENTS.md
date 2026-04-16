# Agent Context

This repository is an Armbian `userpatches` tree for building mPWRD-OS images. It is not a conventional app repo with a package manager, unit-test suite, or single runtime entry point.

## Project Shape

- `README.md` explains the intended checkout flow: clone `armbian/build`, then clone this repo as `userpatches`.
- `global-config.conf` contains shared Armbian build settings. Current default release is `trixie`.
- `config-*.conf` files are board-specific Armbian build configs. They source `global-config.conf` and sometimes a `family-*.conf`.
- `family-rk3506.conf` and `family-rv1106.conf` set shared kernel branch and extension choices for board families.
- `customize-image.sh` is the main chroot image customization script. Most package setup, Meshtastic setup, overlays, and board-specific behavior flow through this file.
- `extensions/` contains Armbian extension hooks that modify the image during build stages.
- `overlay/fs/` is copied into the image root by `customize-image.sh`.
- `overlay/dtbo/rockchip/` contains device tree overlays compiled into `/boot/overlay-user`.

## Important Build Flow

`customize-image.sh` receives:

1. `RELEASE`
2. `LINUXFAMILY`
3. `BOARD`
4. `BUILD_DESKTOP`

The main function:

1. Runs apt updates.
2. Adds Meshtastic and mPWRD repositories.
3. Installs `meshtasticd`, `mpwrd-menu`, `pipx`, Cockpit, and utility packages.
4. Optionally installs global `pipx` packages on newer releases.
5. Applies `overlay/fs`.
6. Runs board-specific customizations.
7. Cleans apt lists.
8. Compiles DTBOs from `overlay/dtbo/${LINUXFAMILY}`.

## Known Review Findings

See `CODE_REVIEW.md` for detailed findings. Short version:

- The 2026-04-15 static findings were addressed in the current staged worktree.
- No outstanding static review findings remain in `CODE_REVIEW.md` as of 2026-04-16.
- Remaining risk is dynamic: full image builds, boot ordering on hardware, apt repository validation, overlay activation, and Meshtastic config generation still need target validation.

## Useful Commands

Static syntax check:

```sh
bash -n customize-image.sh extensions/performance/*.sh extensions/quality/*.sh extensions/*.sh
```

List files:

```sh
rg --files
```

Targeted review searches:

```sh
rg -n "allow-unauthenticated|curl|apt-get|pipx|sed -i|user_overlays|overlays=|mpwrd|mprwd"
rg -n "ENABLE_EXTENSIONS|BOARD=|RELEASE=|BRANCH="
```

`shellcheck` was not installed during the prior review. If available later, run it against the shell scripts before making broad shell changes.

## Editing Notes

- Keep changes scoped. This repo is mostly declarative Armbian config plus shell hooks.
- Prefer anchored matches when editing `/boot/armbianEnv.txt`.
- Treat chroot paths in `customize-image.sh` as image-root paths, not host paths.
- `userpatches/overlay` is bind-mounted to `/tmp/overlay` inside the chroot; `customize-image.sh` relies on that.
- Do not assume `overlay/dtbo/rockchip/*.dts` applies to every board; board-specific enablement is in `BoardSpecific`.
- If changing apt repository setup, preserve support for Debian and Ubuntu branches in the release `case`.
- If changing service ordering, consider both NetworkManager and systemd-networkd because the repo has hooks for both.

## Verification Gaps

The prior review only did static inspection and Bash syntax checks. It did not build an image or boot a board. High-value dynamic checks would be:

- Full Armbian build for at least one RK3506 board and one RV1106/RV1103 board.
- Confirm apt repositories and keys work without `--allow-unauthenticated`.
- Confirm `/boot/armbianEnv.txt` overlay settings after image customization.
- Confirm Meshtastic config files exist and have expected ownership.
- Confirm boot ordering for MAC fix, rfkill unblock, NetworkManager, and Bluetooth on target hardware.
