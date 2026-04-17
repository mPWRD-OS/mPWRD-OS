# Nymea-NetworkManager BLE WiFi provisioning
# https://github.com/nymea/nymea-networkmanager/#configuration

function extension_prepare_config__add_nymea_networkmanager() {
	# Only tested on trixie
	case "${RELEASE}" in
		trixie)
			display_alert "Extension: ${EXTENSION}" "Adding nymea-networkmanager package" "info"
			add_packages_to_image nymea-networkmanager
			;;
		*)
			display_alert "Extension: ${EXTENSION}" "Nymea-NetworkManager not supported on release: ${RELEASE}" "wrn"
			;;
	esac
}

function post_family_tweaks__configure_nymea_nm() {
	# Only configure on trixie (where the package is installed)
	case "${RELEASE}" in
		trixie)
			display_alert "Extension: ${EXTENSION}" "Configuring nymea-networkmanager" "info"
			local conf="${SDCARD}/etc/nymea/nymea-networkmanager.conf"
			if [[ -f "${conf}" ]]; then
				# Set Mode to 'once' in nymea-networkmanager config
				sed -i 's/^Mode=.*/Mode=once/' "${conf}"
				# Set AdvertiseName to 'mpwrd-nm' in nymea-networkmanager config
				sed -i 's/^AdvertiseName=.*/AdvertiseName=mpwrd-nm/' "${conf}"
				# Set PlatformName to 'mpwrd-os' in nymea-networkmanager config
				sed -i 's/^PlatformName=.*/PlatformName=mpwrd-os/' "${conf}"
			else
				display_alert "Extension: ${EXTENSION}" "nymea-networkmanager.conf not found, skipping configuration" "wrn"
			fi
			;;
	esac
}