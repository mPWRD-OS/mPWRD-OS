# Add Tailscale repo
# install tailscale

function custom_apt_repo__add_tailscale_repo() {
	local distro codename
	case $DISTRIBUTION in
		Debian)
			distro="debian"
			;;
		Ubuntu)
			distro="ubuntu"
			;;
		*)
			display_alert "Unsupported distribution for Tailscale: ${DISTRIBUTION}"
			exit 1
			;;
	esac
	codename="${RELEASE}"

	display_alert "Adding Tailscale APT repository for ${DISTRIBUTION} ${codename} (${distro})..."
	# Tailscale ships a pre-dearmored keyring, so no gpg --dearmor is needed.
	run_host_command_logged curl -fsSL "https://pkgs.tailscale.com/stable/${distro}/${codename}.noarmor.gpg" | tee "${SDCARD}/usr/share/keyrings/tailscale-archive-keyring.gpg" > /dev/null
	run_host_command_logged echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/${distro} ${codename} main" | tee "${SDCARD}/etc/apt/sources.list.d/tailscale.list" > /dev/null
}

function extension_prepare_config__add_tailscale() {
	add_packages_to_image tailscale
}
