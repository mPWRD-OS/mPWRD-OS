# Add Tailscale repo
# install tailscale

function custom_apt_repo__add_tailscale_repo() {
	local distro codename keyring_file list_file
	case $DISTRIBUTION in
		Debian)
			distro="debian"
			;;
		Ubuntu)
			distro="ubuntu"
			;;
		*)
			display_alert "Unsupported distribution for Tailscale: ${DISTRIBUTION}" "" "err"
			return 1
			;;
	esac
	codename="${RELEASE}"
	keyring_file="${SDCARD}/usr/share/keyrings/tailscale-archive-keyring.gpg"
	list_file="${SDCARD}/etc/apt/sources.list.d/tailscale.list"

	display_alert "Adding Tailscale APT repository for ${DISTRIBUTION} ${codename} (${distro})..."
	# Ensure the target directories exist; /usr/share/keyrings is absent on a
	# minimal rootfs, and tee/redirect would otherwise fail silently.
	run_host_command_logged mkdir -p "${SDCARD}/usr/share/keyrings" "${SDCARD}/etc/apt/sources.list.d"
	# Tailscale ships a pre-dearmored keyring, so no gpg --dearmor is needed.
	# Write straight to the target file via curl -o (no pipe into tee) so the
	# wrapper's build-log output can never end up inside the keyring.
	run_host_command_logged curl -fsSL "https://pkgs.tailscale.com/stable/${distro}/${codename}.noarmor.gpg" -o "${keyring_file}"
	echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/${distro} ${codename} main" > "${list_file}"
}

function extension_prepare_config__add_tailscale() {
	add_packages_to_image tailscale
}
