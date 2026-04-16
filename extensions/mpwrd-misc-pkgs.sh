# Install misc packages
# Not necessary for mPWRD-OS core functionality, but nice to have around.

function extension_prepare_config__add_mpwrd_misc() {
	# Cockpit
	add_packages_to_image cockpit cockpit-networkmanager
	# Misc
	add_packages_to_image vim git net-tools fonts-noto-color-emoji
	# re-add 'i2c-tools' here when the race condition with family-tweaks is resolved
}
