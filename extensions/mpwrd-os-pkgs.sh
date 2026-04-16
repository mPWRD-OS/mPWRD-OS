# Add mPWRD-OS repo
# install mpwrd-menu

function custom_apt_repo__add_mpwrd_repo() {
	case $RELEASE in
		trixie)
			obs_slug="Debian_13"
			;;
		bookworm)
			obs_slug="Debian_12"
			;;
		resolute)
			obs_slug="xUbuntu_26.04"
			;;
		noble)
			obs_slug="xUbuntu_24.04"
			;;
		*)
			display_alert "Unsupported ${DISTRIBUTION} release: ${RELEASE}"
			exit 1
			;;
	esac
	display_alert "Adding mPWRD-OS OBS repository for ${DISTRIBUTION} ${RELEASE} (${obs_slug})..."
	run_host_command_logged echo "deb http://download.opensuse.org/repositories/home:/mPWRD:/OS/$obs_slug/ /" | tee "${SDCARD}/etc/apt/sources.list.d/home:mPWRD:OS.list"
	run_host_command_logged curl -fsSL https://download.opensuse.org/repositories/home:mPWRD:OS/$obs_slug/Release.key | gpg --dearmor | tee "${SDCARD}/etc/apt/trusted.gpg.d/home_mPWRD_OS.gpg" > /dev/null
}

function extension_prepare_config__add_mpwrd_os() {
	add_packages_to_image mpwrd-menu gpg pipx
}
