#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
	printf 'not ok - %s\n' "$1" >&2
	exit 1
}

assert_contains() {
	local file="$1"
	local pattern="$2"
	local message="$3"
	local path="${repo_root}/${file}"

	if [[ "${file}" = /* ]]; then
		path="${file}"
	fi

	if ! grep -Eq -- "${pattern}" "${path}"; then
		fail "${message}"
	fi
}

assert_not_contains() {
	local file="$1"
	local pattern="$2"
	local message="$3"
	local path="${repo_root}/${file}"

	if [[ "${file}" = /* ]]; then
		path="${file}"
	fi

	if grep -Eq -- "${pattern}" "${path}"; then
		fail "${message}"
	fi
}

assert_release_case_contains() {
	local release="$1"
	local pattern="$2"
	local message="$3"

	if ! awk -v release="${release})" -v pattern="${pattern}" '
		$0 ~ "^[[:space:]]*" release "[[:space:]]*$" { in_case = 1; next }
		in_case && $0 ~ /^[[:space:]]*;;[[:space:]]*$/ { exit found ? 0 : 1 }
		in_case && $0 ~ pattern { found = 1 }
		END { if (in_case && found) exit 0; exit 1 }
	' "${repo_root}/customize-image.sh"; then
		fail "${message}"
	fi
}

assert_contains "customize-image.sh" '^set -euo pipefail$' \
	"customize-image.sh must run with strict shell settings"
assert_not_contains "customize-image.sh" '--allow-unauthenticated' \
	"apt installs must not allow unauthenticated packages"
assert_contains "customize-image.sh" 'https://download\.opensuse\.org/repositories/network:/Meshtastic:/beta/' \
	"Meshtastic OBS apt source must use HTTPS"
assert_contains "customize-image.sh" 'https://download\.opensuse\.org/repositories/home:/mPWRD:/OS/' \
	"mPWRD OBS apt source must use HTTPS"
assert_contains "customize-image.sh" 'MESHTASTIC_OBS_KEYRING="\$\{APT_KEYRING_DIR\}/network_Meshtastic_beta\.gpg"' \
	"Meshtastic OBS keyring path must be under /etc/apt/keyrings"
assert_contains "customize-image.sh" 'signed-by=\$\{MESHTASTIC_OBS_KEYRING\}' \
	"Meshtastic OBS apt source must use signed-by keyring"
assert_contains "customize-image.sh" 'MPWRD_OBS_KEYRING="\$\{APT_KEYRING_DIR\}/home_mPWRD_OS\.gpg"' \
	"mPWRD OBS keyring path must be under /etc/apt/keyrings"
assert_contains "customize-image.sh" 'signed-by=\$\{MPWRD_OBS_KEYRING\}' \
	"mPWRD OBS apt source must use signed-by keyring"
assert_release_case_contains "resolute" 'obs_slug="xUbuntu_24[.]04"' \
	"resolute must temporarily use the published xUbuntu_24.04 mPWRD OBS repository"
assert_contains "customize-image.sh" 'grep -q "\^user_overlays="' \
	"user_overlays detection must be anchored"
assert_contains "customize-image.sh" 'grep -q "\^overlays="' \
	"overlays detection must be anchored"
assert_contains "customize-image.sh" 'MACAddressSource.*not found' \
	"Meshtastic MACAddressSource update must fail clearly when key is missing"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

export SDCARD="${tmpdir}/sdcard"
export BOARD="test-board"
export EXTENSION="test-extension"
mkdir -p "${SDCARD}/etc/systemd/system"

display_alert() {
	:
}

chroot_sdcard() {
	:
}

# shellcheck source=/dev/null
source "${repo_root}/extensions/quality/fixed-eth-mac.sh"
post_repo_customize_image__700_fixed_eth_mac

fixed_mac_service="${SDCARD}/etc/systemd/system/mpwrd-fixed-eth-mac.service"
assert_contains "${fixed_mac_service}" '^Before=NetworkManager\.service systemd-networkd\.service network-pre\.target$' \
	"fixed MAC service must explicitly order before network managers"
assert_contains "${fixed_mac_service}" '^Wants=network-pre\.target$' \
	"fixed MAC service must pull in network-pre.target"

# shellcheck source=/dev/null
source "${repo_root}/extensions/unblock-rfkill.sh"
pre_install_distribution_specific__unblock_rfkill

rfkill_service="${SDCARD}/etc/systemd/system/unblock-rfkill.service"
assert_not_contains "${rfkill_service}" 'After=multi-user\.target' \
	"rfkill unblock must not run after multi-user.target"
assert_contains "${rfkill_service}" '^Before=network-pre\.target NetworkManager\.service bluetooth\.service$' \
	"rfkill unblock must run before NetworkManager and Bluetooth"
assert_contains "${rfkill_service}" '^WantedBy=network-pre\.target$' \
	"rfkill unblock must be wanted by network-pre.target"

assert_contains "overlay/fs/etc/update-motd.d/42-mpwrd-commands" 'mpwrd-menu' \
	"MOTD must advertise mpwrd-menu"
assert_not_contains "overlay/fs/etc/update-motd.d/42-mpwrd-commands" 'mprwd-menu' \
	"MOTD must not advertise misspelled mprwd-menu"
assert_contains "extensions/performance/perf-tmp-rootfs.sh" 'Bind /opt/tmp onto /tmp' \
	"/tmp bind mount comment must match implementation"

printf 'ok - code review regressions\n'
