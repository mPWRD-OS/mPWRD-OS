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
assert_contains "extensions/meshtasticd.sh" '^function post_family_tweaks__700_install_meshtasticd\(\)' \
	"meshtasticd extension must install packages via a real post_family_tweaks hook"
assert_contains "extensions/meshtasticd.sh" '^function post_family_tweaks__710_configure_meshtasticd\(\)' \
	"meshtasticd extension must configure board-specific state via a real post_family_tweaks hook"
assert_contains "extensions/meshtasticd.sh" 'grep -q "\^user_overlays="' \
	"user_overlays detection must be anchored in the meshtasticd extension"
assert_contains "extensions/meshtasticd.sh" 'grep -q "\^overlays="' \
	"overlays detection must be anchored in the meshtasticd extension"
assert_contains "extensions/meshtasticd.sh" 'MACAddressSource.*not found' \
	"Meshtastic MACAddressSource update must fail clearly when key is missing"
assert_contains "extensions/meshtasticd.sh" '\$\{SDCARD\}/etc/meshtasticd/config\.yaml' \
	"meshtasticd config updates in the extension must target the image root via SDCARD"
assert_contains "extensions/meshtasticd.sh" 'chroot_sdcard apt-get update' \
	"meshtasticd extension install hook must refresh apt metadata inside the chroot"
assert_contains "extensions/meshtasticd.sh" 'chroot_sdcard apt-get --yes install meshtasticd i2c-tools' \
	"meshtasticd extension install hook must install meshtasticd and i2c-tools via chroot"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

export SDCARD="${tmpdir}/sdcard"
export BOARD="test-board"
export EXTENSION="test-extension"
mkdir -p "${SDCARD}/etc/apt" "${SDCARD}/etc/systemd/system"

display_alert() {
	:
}

run_host_command_logged() {
	case "$1" in
		install | chmod)
			"$@"
			;;
		curl)
			shift
			local output=""
			while (($#)); do
				case "$1" in
					-o)
						output="$2"
						shift 2
						;;
					*)
						shift
						;;
				esac
			done
			printf 'fake release key\n' > "${output}"
			;;
		gpg)
			shift
			local output=""
			local input=""
			while (($#)); do
				case "$1" in
					-o)
						output="$2"
						shift 2
						;;
					--batch | --yes | --dearmor)
						shift
						;;
					*)
						input="$1"
						shift
						;;
				esac
			done
			cp "${input}" "${output}"
			;;
		*)
			fail "unsupported run_host_command_logged stub invocation: $*"
			;;
	esac
}

do_with_retries() {
	printf '%s\n' "$*" > "${tmpdir}/do_with_retries.log"
}

chroot_sdcard() {
	printf '%s\n' "$*" >> "${tmpdir}/chroot.log"
}

# shellcheck source=/dev/null
source "${repo_root}/extensions/obs-bootstrap.sh"
# shellcheck source=/dev/null
source "${repo_root}/extensions/meshtasticd.sh"
# shellcheck source=/dev/null
source "${repo_root}/extensions/mpwrd-os-pkgs.sh"

export DISTRIBUTION="Debian"
export RELEASE="trixie"
export MESHTASTICD_CHANNEL="beta"
custom_apt_repo__add_meshtasticd_repo

meshtastic_repo_list="${SDCARD}/etc/apt/sources.list.d/network:Meshtastic:beta.list"
meshtastic_keyring="${SDCARD}/etc/apt/keyrings/network_Meshtastic_beta.gpg"
assert_contains "${meshtastic_repo_list}" '^deb \[signed-by=/etc/apt/keyrings/network_Meshtastic_beta\.gpg\] https://download\.opensuse\.org/repositories/network:/Meshtastic:/beta/Debian_13/ /$' \
	"Meshtastic OBS apt source must use HTTPS and signed-by keyring"
assert_not_contains "${meshtastic_repo_list}" 'http://' \
	"Meshtastic OBS apt source must not use HTTP"
assert_contains "${meshtastic_keyring}" 'fake release key' \
	"Meshtastic OBS keyring must be written under /etc/apt/keyrings"
if [[ -e "${SDCARD}/etc/apt/trusted.gpg.d/network_Meshtastic_beta.gpg" ]]; then
	fail "Meshtastic OBS keyring must not be written under trusted.gpg.d"
fi

export DISTRIBUTION="Ubuntu"
export RELEASE="resolute"
custom_apt_repo__add_mpwrd_repo

mpwrd_repo_list="${SDCARD}/etc/apt/sources.list.d/home:mPWRD:OS.list"
mpwrd_keyring="${SDCARD}/etc/apt/keyrings/home_mPWRD_OS.gpg"
assert_contains "${mpwrd_repo_list}" '^deb \[signed-by=/etc/apt/keyrings/home_mPWRD_OS\.gpg\] https://download\.opensuse\.org/repositories/home:/mPWRD:/OS/xUbuntu_26\.04/ /$' \
	"resolute must use the published xUbuntu_26.04 mPWRD OBS repository with signed-by"
assert_not_contains "${mpwrd_repo_list}" 'http://' \
	"mPWRD OBS apt source must not use HTTP"
assert_contains "${mpwrd_keyring}" 'fake release key' \
	"mPWRD OBS keyring must be written under /etc/apt/keyrings"
if [[ -e "${SDCARD}/etc/apt/trusted.gpg.d/home_mPWRD_OS.gpg" ]]; then
	fail "mPWRD OBS keyring must not be written under trusted.gpg.d"
fi

: > "${tmpdir}/chroot.log"
post_family_tweaks__700_install_meshtasticd
assert_contains "${tmpdir}/chroot.log" '^apt-get update$' \
	"meshtasticd extension install hook must refresh apt metadata before install"
assert_contains "${tmpdir}/chroot.log" '^apt-get --yes install meshtasticd i2c-tools$' \
	"meshtasticd extension install hook must install meshtasticd and i2c-tools"

mkdir -p "${SDCARD}/boot" "${SDCARD}/etc/meshtasticd/config.d"
cat > "${SDCARD}/boot/armbianEnv.txt" <<'EOF_ARMBIANENV'
verbosity=1
EOF_ARMBIANENV
cat > "${SDCARD}/etc/meshtasticd/config.yaml" <<'EOF_MESHTASTIC'
General:
  MACAddressSource: default
EOF_MESHTASTIC

export BOARD="luckfox-lyra-ultra-w"
post_family_tweaks__710_configure_meshtasticd
assert_contains "${SDCARD}/boot/armbianEnv.txt" '^overlays=luckfox-lyra-ultra-w-spi0-1cs-spidev$' \
	"meshtasticd config hook must enable required kernel overlays"
assert_contains "${SDCARD}/boot/armbianEnv.txt" '^user_overlays=luckfox-lyra-ultra-w-uart1 luckfox-lyra-ultra-w-i2c0$' \
	"meshtasticd config hook must enable required user overlays"
assert_contains "${SDCARD}/etc/meshtasticd/config.yaml" '^[[:space:]]*MACAddressSource:[[:space:]]*end1$' \
	"meshtasticd config hook must update MACAddressSource for the target board"
assert_contains "${SDCARD}/etc/meshtasticd/config.d/lora-lyra-ultra_2w.yaml" 'fake release key' \
	"meshtasticd config hook must download the board-specific Meshtastic config fragment"
assert_contains "${tmpdir}/chroot.log" '^chown -R meshtasticd:meshtasticd /etc/meshtasticd/config.d$' \
	"meshtasticd config hook must fix ownership for config fragments"

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
