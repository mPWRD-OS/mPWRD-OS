#
# Extension to manage network interfaces with NetworkManager + Netplan
#

function __meshtasticd_obs() {
	case "${RELEASE}" in
		trixie)
			debian_slug="Debian_13"
			;;
		bookworm)
			debian_slug="Debian_12"
			;;
		*)
			display_alert "Unsupported Debian release: ${RELEASE}"
			exit 1
			;;
	esac
	display_alert "Adding meshtasticd OBS repository for ${DISTRIBUTION} ${RELEASE} (${debian_slug})..."
	run_host_command_logged echo "deb http://download.opensuse.org/repositories/network:/Meshtastic:/beta/$debian_slug/ /" | tee "${SDCARD}"/etc/apt/sources.list.d/network:Meshtastic:beta.list
	run_host_command_logged curl -fsSL https://download.opensuse.org/repositories/network:Meshtastic:beta/$debian_slug/Release.key | gpg --dearmor | tee "${SDCARD}"/etc/apt/trusted.gpg.d/network_Meshtastic_beta.gpg > /dev/null
}

function __meshtasticd_ppa() {
	display_alert "Adding meshtasticd PPA repository for ${DISTRIBUTION} ${RELEASE}..."
	do_with_retries 3 chroot_sdcard add-apt-repository -y ppa:meshtastic/beta
}

function custom_apt_repo__add_meshtasticd_repo() {
	if [[ "${DISTRIBUTION}" == "Ubuntu" ]]; then
		__meshtasticd_ppa
	elif [[ "${DISTRIBUTION}" == "Debian" ]]; then
		__meshtasticd_obs
	else
		display_alert "Unsupported distribution: ${DISTRIBUTION}"
		exit 1
	fi
}

function post_repo_customize_image__install_meshtasticd() {
	chroot_sdcard_apt_get install -y meshtasticd
}
