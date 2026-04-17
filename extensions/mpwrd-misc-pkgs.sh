# shellcheck shell=bash
#
# Install misc packages
# Not necessary for mPWRD-OS core functionality, but nice to have around.

function extension_prepare_config__add_mpwrd_misc() {
	# Cockpit
	add_packages_to_image cockpit cockpit-networkmanager
	# Misc
	add_packages_to_image vim git net-tools fonts-noto-color-emoji
	# re-add 'i2c-tools' here when the race condition with family-tweaks is resolved
	add_packages_to_image apt-utils ccze curl evtest gpiod htop iftop iputils-ping jq libbluetooth-dev libgpiod-dev liborcania-dev libssl-dev libulfius-dev libyaml-cpp-dev lsof minicom mtd-utils nano openssl protobuf-compiler python-is-python3 python3-luma.oled python3-pip python3-serial python3-setuptools python3-spidev python3-venv python3-wheel rsync screen socat spi-tools ssh telnet tio tmux unzip usbutils wget wireless-tools zsh
}
