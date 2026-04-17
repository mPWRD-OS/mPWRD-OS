# shellcheck shell=bash
#
# Add mPWRD-OS repo
# install mpwrd-menu

function __mpwrd_obs_slug() {
	case "${RELEASE}" in
		trixie)
			printf '%s\n' "Debian_13"
			;;
		bookworm)
			printf '%s\n' "Debian_12"
			;;
		resolute)
			printf '%s\n' "xUbuntu_26.04"
			;;
		noble)
			printf '%s\n' "xUbuntu_24.04"
			;;
		*)
			display_alert "Unsupported ${DISTRIBUTION} release: ${RELEASE}"
			exit 1
			;;
	esac
}

function custom_apt_repo__add_mpwrd_repo() {
	local obs_slug
	obs_slug="$(__mpwrd_obs_slug)"
	display_alert "Adding mPWRD-OS OBS repository for ${DISTRIBUTION} ${RELEASE} (${obs_slug})..."
	__obs_bootstrap_add_signed_repo \
		"https://download.opensuse.org/repositories/home:/mPWRD:/OS/${obs_slug}/" \
		"https://download.opensuse.org/repositories/home:mPWRD:OS/${obs_slug}/Release.key" \
		"home:mPWRD:OS.list" \
		"home_mPWRD_OS.gpg"
}

function extension_prepare_config__add_mpwrd_os() {
	add_packages_to_image mpwrd-menu gpg pipx
}
