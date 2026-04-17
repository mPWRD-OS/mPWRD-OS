# shellcheck shell=bash
#
# Add meshtasticd repo
# install meshtasticd

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

# Temporarily disabled: gpio + ic2 groups race condition
# Instead installed with customize-image.sh
# function extension_prepare_config__add_meshtasticd() {
# 	add_packages_to_image meshtasticd
# }
