# Add meshtasticd repo
# install meshtasticd

function custom_apt_repo__add_meshtasticd_repo() {
	[[ -z $MESHTASTICD_CHANNEL ]] && return 1
	case $DISTRIBUTION in
		Debian)
			case "${RELEASE}" in
				trixie)
					obs_slug="Debian_13"
					;;
				bookworm)
					obs_slug="Debian_12"
					;;
				*)
					display_alert "Unsupported Debian release: ${RELEASE}"
					exit 1
					;;
			esac
			display_alert "Adding meshtasticd OBS repository for ${DISTRIBUTION} ${RELEASE} (${obs_slug})..."
			run_host_command_logged echo "deb http://download.opensuse.org/repositories/network:/Meshtastic:/${MESHTASTICD_CHANNEL}/$obs_slug/ /" | tee "${SDCARD}/etc/apt/sources.list.d/network:Meshtastic:${MESHTASTICD_CHANNEL}.list"
			run_host_command_logged curl -fsSL "https://download.opensuse.org/repositories/network:Meshtastic:${MESHTASTICD_CHANNEL}/$obs_slug/Release.key" | gpg --dearmor | tee "${SDCARD}/etc/apt/trusted.gpg.d/network_Meshtastic_${MESHTASTICD_CHANNEL}.gpg" > /dev/null
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

# Temporarily disabled: gpio + ic2 groups race condition
# Instead installed with customize-image.sh
# function extension_prepare_config__add_meshtasticd() {
# 	add_packages_to_image meshtasticd
# }
