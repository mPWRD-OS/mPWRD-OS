# Add Tailscale repo
# install tailscale

# Tailscale/tailscaled is too heavy for low-memory boards (e.g. Luckfox Pico
# Mini). When the armbian `lowmem` extension is enabled, skip it entirely.
function _tailscale_lowmem_enabled() {
if [[ "$(type -t post_family_tweaks__enable_lowmem_mkswap)" == "function" ]]; then
	# lowmem is enabled
	return 0
fi
return 1
}

function custom_apt_repo__add_tailscale_repo() {
	local distro codename keyring_file list_file

	if _tailscale_lowmem_enabled; then
		display_alert "Skipping Tailscale repo on low-memory board (lowmem extension enabled)" "" "info"
		return 0
	fi
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
	if _tailscale_lowmem_enabled; then
		display_alert "Skipping Tailscale package on low-memory board (lowmem extension enabled)" "" "info"
		return 0
	fi
	add_packages_to_image tailscale
}
