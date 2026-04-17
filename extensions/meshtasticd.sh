# shellcheck shell=bash
#
# Add meshtasticd repo and apply board-specific Meshtastic configuration.
#

function __meshtasticd_obs_slug() {
	case "${RELEASE}" in
		trixie)
			printf '%s\n' "Debian_13"
			;;
		bookworm)
			printf '%s\n' "Debian_12"
			;;
		*)
			display_alert "Unsupported Debian release: ${RELEASE}"
			exit 1
			;;
	esac
}

function custom_apt_repo__add_meshtasticd_repo() {
	[[ -z "${MESHTASTICD_CHANNEL:-}" ]] && return 1
	case "${DISTRIBUTION}" in
		Debian)
			local obs_slug
			obs_slug="$(__meshtasticd_obs_slug)"
			display_alert "Adding meshtasticd OBS repository for ${DISTRIBUTION} ${RELEASE} (${obs_slug})..."
			__obs_bootstrap_add_signed_repo \
				"https://download.opensuse.org/repositories/network:/Meshtastic:/${MESHTASTICD_CHANNEL}/${obs_slug}/" \
				"https://download.opensuse.org/repositories/network:Meshtastic:${MESHTASTICD_CHANNEL}/${obs_slug}/Release.key" \
				"network:Meshtastic:${MESHTASTICD_CHANNEL}.list" \
				"network_Meshtastic_${MESHTASTICD_CHANNEL}.gpg"
			;;
		Ubuntu)
			display_alert "Adding meshtasticd PPA repository for ${DISTRIBUTION} ${RELEASE}..."
			do_with_retries 3 chroot_sdcard add-apt-repository -y "ppa:meshtastic/${MESHTASTICD_CHANNEL}"
			;;
		*)
			display_alert "Unsupported distribution: ${DISTRIBUTION}"
			exit 1
			;;
	esac
}

function __meshtasticd_enable_user_overlay() {
	local user_overlays="$1"
	local armbian_env="${SDCARD}/boot/armbianEnv.txt"

	if [[ ! -f "${armbian_env}" ]]; then
		echo "Warning: ${armbian_env} not found, cannot enable device tree overlays"
		return 0
	fi

	if grep -q "^user_overlays=" "${armbian_env}"; then
		sed -i "s/^user_overlays=\(.*\)/user_overlays=\1 ${user_overlays}/" "${armbian_env}"
	else
		echo "user_overlays=${user_overlays}" >> "${armbian_env}"
	fi
}

function __meshtasticd_enable_kernel_overlay() {
	local overlay_name="$1"
	local armbian_env="${SDCARD}/boot/armbianEnv.txt"

	if [[ ! -f "${armbian_env}" ]]; then
		echo "Warning: ${armbian_env} not found, cannot enable device tree overlays"
		return 0
	fi

	if grep -q "^overlays=" "${armbian_env}"; then
		sed -i "s/^overlays=\(.*\)/overlays=\1 ${overlay_name}/" "${armbian_env}"
	else
		echo "overlays=${overlay_name}" >> "${armbian_env}"
	fi
}

function __meshtasticd_set_mac_src() {
	local iface_name="$1"
	local config_file="${SDCARD}/etc/meshtasticd/config.yaml"

	if [[ ! -f "${config_file}" ]]; then
		echo "Error: ${config_file} not found; cannot set MACAddressSource" >&2
		exit 1
	fi

	if ! grep -Eq '^[[:space:]]*#?[[:space:]]*MACAddressSource:' "${config_file}"; then
		echo "Error: MACAddressSource not found in ${config_file}; cannot set it to ${iface_name}" >&2
		exit 1
	fi

	sed -i "s/^[[:space:]]*#\?[[:space:]]*MACAddressSource:.*/  MACAddressSource: ${iface_name}/" "${config_file}"

	if ! grep -Eq "^[[:space:]]*MACAddressSource:[[:space:]]*${iface_name}([[:space:]]|$)" "${config_file}"; then
		echo "Error: failed to set MACAddressSource to ${iface_name} in ${config_file}" >&2
		exit 1
	fi
}

function __meshtasticd_download_board_config() {
	local source_url="$1"
	local output_file="$2"

	run_host_command_logged install -d -m 0755 "${SDCARD}/etc/meshtasticd/config.d"
	run_host_command_logged curl -fsSL "${source_url}" -o "${SDCARD}/etc/meshtasticd/config.d/${output_file}"
}

function __meshtasticd_configure_board() {
	case "${BOARD}" in
		ebyte-ecb41-pge)
			__meshtasticd_enable_user_overlay "ebyte-ecb41-pge-spi0-1cs-spidev"
			__meshtasticd_set_mac_src "end0"
			;;
		forlinx-ok3506-s12)
			__meshtasticd_enable_kernel_overlay "forlinx-ok3506-s12-spi0-1cs-spidev"
			__meshtasticd_set_mac_src "end0"
			;;
		luckfox-lyra-plus)
			__meshtasticd_enable_kernel_overlay "luckfox-lyra-plus-spi0-1cs_rmio13-spidev"
			__meshtasticd_set_mac_src "end1"
			__meshtasticd_download_board_config \
				"https://raw.githubusercontent.com/meshtastic/firmware/refs/tags/v2.7.22.96dd647/bin/config.d/lora-lyra-ws-raspberry-pi-pico-hat.yaml" \
				"lora-lyra-ws-raspberry-pi-pico-hat.yaml"
			;;
		luckfox-lyra-ultra-w)
			__meshtasticd_enable_kernel_overlay "luckfox-lyra-ultra-w-spi0-1cs-spidev"
			__meshtasticd_enable_user_overlay "luckfox-lyra-ultra-w-uart1"
			__meshtasticd_enable_user_overlay "luckfox-lyra-ultra-w-i2c0"
			__meshtasticd_set_mac_src "end1"
			__meshtasticd_download_board_config \
				"https://raw.githubusercontent.com/meshtastic/firmware/refs/tags/v2.7.22.96dd647/bin/config.d/lora-lyra-ultra_2w.yaml" \
				"lora-lyra-ultra_2w.yaml"
			;;
		luckfox-lyra-zero-w)
			__meshtasticd_enable_kernel_overlay "luckfox-lyra-zero-w-spi0-1cs-spidev"
			;;
		luckfox-pico-max)
			__meshtasticd_set_mac_src "eth0"
			__meshtasticd_download_board_config \
				"https://github.com/meshtastic/firmware/raw/466cc4cecddd11cd1bb0d0b166bd658d116832b3/bin/config.d/lora-luckfox-pico-max-ws-raspberry-pi-pico-hat.yaml" \
				"lora-luckfox-pico-max-ws-raspberry-pi-pico-hat.yaml"
			;;
		luckfox-pico-mini)
			__meshtasticd_set_mac_src "eth0"
			__meshtasticd_download_board_config \
				"https://raw.githubusercontent.com/meshtastic/firmware/refs/tags/v2.7.22.96dd647/bin/config.d/lora-femtofox_SX1262_TCXO.yaml" \
				"lora-femtofox_SX1262_TCXO.yaml"
			;;
		rpi4b)
			__meshtasticd_set_mac_src "end0"
			;;
		*)
			echo "No meshtasticd board-specific customizations for board: ${BOARD}"
			;;
	esac
}

function post_family_tweaks__700_install_meshtasticd() {
	display_alert "Extension: ${EXTENSION}" "Installing meshtasticd and i2c-tools" "info"
	chroot_sdcard apt-get update
	chroot_sdcard apt-get --yes install meshtasticd i2c-tools
}

function post_family_tweaks__710_configure_meshtasticd() {
	display_alert "Extension: ${EXTENSION}" "Applying meshtasticd board-specific configuration" "info"
	run_host_command_logged install -d -m 0755 "${SDCARD}/etc/meshtasticd/config.d"
	__meshtasticd_configure_board
	chroot_sdcard chown -R meshtasticd:meshtasticd /etc/meshtasticd/config.d
}
