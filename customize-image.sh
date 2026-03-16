#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot
# The sd card's root path is accessible via $SDCARD variable.

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

# 'Global' env vars for all functions in this script
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

# Release-specific variables
case $RELEASE in
	trixie)
		DISTRIBUTION="Debian"
		obs_slug="Debian_13"
		pipx_g=true
		;;
	bookworm)
		DISTRIBUTION="Debian"
		obs_slug="Debian_12"
		pipx_g=false
		;;
	resolute)
		DISTRIBUTION="Ubuntu"
		obs_slug="xUbuntu_26.04"
		pipx_g=true
		;;
	noble)
		DISTRIBUTION="Ubuntu"
		obs_slug="xUbuntu_24.04"
		pipx_g=false
		;;
	*)
		# Exit early for unsupported releases
		echo "Unsupported mPWRD RELEASE: $RELEASE"
		exit 1
		;;
esac

Main() {
	apt-get update
	InstallAptPkg "gpg"
	AddMeshtasticRepo
	apt-get update
	InstallAptPkg "meshtasticd"
	InstallAptPkg "pipx"
	InstallAptPkg "avahi-daemon"
	InstallAptPkg "cockpit cockpit-networkmanager"
	case $pipx_g in
		true)
			InstallPipxPkg "meshtastic"
			InstallPipxPkg "contact"
			;;
		*)
			echo "'pipx install --global' skipped for ${RELEASE} due to old pipx version."
			echo "Target Debian 13+ or Ubuntu 26.04+ for pipx global support."
			;;
	esac
	# Always run
	ApplyFSOverlay
	CleanupApt
	CompileDTBO
} # Main

ApplyFSOverlay() {
	# Copy overlay files to their destinations
	# replacing existing files
	cp -r /tmp/overlay/fs/* /
} # ApplyFSOverlay

AddMeshtasticRepo() {
	case $DISTRIBUTION in
		Debian)
			__AddMeshtasticRepo_Debian_OBS
			;;
		Ubuntu)
			__AddMeshtasticRepo_Ubuntu_PPA
			;;
	esac
} # AddMeshtasticRepo

__AddMeshtasticRepo_Debian_OBS() {
	echo "deb http://download.opensuse.org/repositories/network:/Meshtastic:/beta/$obs_slug/ /" | tee /etc/apt/sources.list.d/network:Meshtastic:beta.list
	curl -fsSL https://download.opensuse.org/repositories/network:Meshtastic:beta/$obs_slug/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/network_Meshtastic_beta.gpg > /dev/null
} # __AddMeshtasticRepo_Debian_OBS

__AddMeshtasticRepo_Ubuntu_PPA() {
	add-apt-repository --yes ppa:meshtastic/beta
} # __AddMeshtasticRepo_Ubuntu_PPA

InstallAptPkg() {
	PKGSPEC="$1"
	# Install package via apt-get
	echo "APT: Installing ${PKGSPEC}..."
	apt-get --yes --allow-unauthenticated \
		install $PKGSPEC
} # InstallAptPkg

InstallPipxPkg() {
	PKGSPEC="$1"
	# Install package via 'pipx install --global'
	pipx install --global "${PKGSPEC}"
	# --global flag requires pipx 1.5.0 or newer
} # InstallPipxPkg

CleanupApt() {
	apt-get clean
	rm -rf /var/lib/apt/lists/*
} # CleanupApt

CompileDTBO() {
	# Always compile DTBOs for each family (even if not enabled by default)
	mkdir -p /boot/overlay-user
	echo "Compiling mPWRD device tree overlays for ${LINUXFAMILY}"
	echo "located in overlay/dtbo/${LINUXFAMILY}"
	shopt -s nullglob
	# If *.dts returns no results, the loop will not execute (desired behavior)
	for f in /tmp/overlay/dtbo/"${LINUXFAMILY}"/*.dts; do
		DTBO_NAME=$(basename "${f}" .dts)
		echo "Compiling ${DTBO_NAME}"
		dtc -@ -q -I dts -O dtb -o "/boot/overlay-user/${DTBO_NAME}.dtbo" "${f}"
	done
	shopt -u nullglob
} # CompileDTBO

EnableUserDTOverlay() {
	USER_OVERLAYS="$1"
	echo "Enabling user_overlays: ${USER_OVERLAYS}"
	# Enable overlays (space separated)
	# in /boot/armbianEnv.txt
	if [ -f /boot/armbianEnv.txt ]; then
		if grep -q "user_overlays=" /boot/armbianEnv.txt; then
			# Append to existing user_overlays
			sed -i "s/user_overlays=\(.*\)/user_overlays=\1 ${USER_OVERLAYS}/" /boot/armbianEnv.txt
		else
			# Add new user_overlays line
			echo "user_overlays=${USER_OVERLAYS}" >> /boot/armbianEnv.txt
		fi
	else
		echo "Warning: /boot/armbianEnv.txt not found, cannot enable device tree overlays"
	fi
} # EnableUserDTOverlay

EnableKernelDTOverlay() {
	OVERLAY_NAME="$1"
	echo "Enabling kernel (builtin) overlay: ${OVERLAY_NAME}"
	# Enable overlay in /boot/armbianEnv.txt
	if [ -f /boot/armbianEnv.txt ]; then
		if grep -q "overlays=" /boot/armbianEnv.txt; then
			# Append to existing overlays
			sed -i "s/overlays=\(.*\)/overlays=\1 ${OVERLAY_NAME}/" /boot/armbianEnv.txt
		else
			# Add new overlays line
			echo "overlays=${OVERLAY_NAME}" >> /boot/armbianEnv.txt
		fi
	else
		echo "Warning: /boot/armbianEnv.txt not found, cannot enable device tree overlays"
	fi
}

MTSetMacSrc() {
	iface_name="$1"
	# Set the General.MACAddressSource to $iface_name
	# for meshtasticd (/etc/meshtasticd/config.yaml)
	sed -i "s/^#\?  MACAddressSource: .*/  MACAddressSource: $iface_name/" /etc/meshtasticd/config.yaml
} # MTSetMacSrc

BoardSpecific() {
	case $BOARD in
		forlinx-ok3506-s12)
			# Enable forlinx-ok3506-s12-spi0-1cs-spidev overlay
			EnableKernelDTOverlay "forlinx-ok3506-s12-spi0-1cs-spidev"
			# Set meshtasticd MacAddressSource to 'end1' for forlinx-ok3506-s12
			MTSetMacSrc "end1"
			;;
		luckfox-lyra-plus)
			# Enable luckfox-lyra-plus-spi0-1cs_rmio13-spidev overlay
			EnableKernelDTOverlay "luckfox-lyra-plus-spi0-1cs_rmio13-spidev"
			# Set meshtasticd MacAddressSource to 'end1' for lyra-plus
			MTSetMacSrc "end1"
			# Download waveshare pico config for lyra-plus
			curl -fsSL https://github.com/meshtastic/firmware/raw/607b631114349234b8859c2da0d0f553b3d344f3/bin/config.d/lora-lyra-ws-raspberry-pi-pico-hat.yaml \
				-o /etc/meshtasticd/config.d/lora-lyra-ws-raspberry-pi-pico-hat.yaml
			;;
		luckfox-lyra-ultra-w)
			# Enable devicetree overlays
			EnableKernelDTOverlay "luckfox-lyra-ultra-w-spi0-1cs-spidev"
			EnableUserDTOverlay "luckfox-lyra-ultra-w-uart1"
			EnableUserDTOverlay "luckfox-lyra-ultra-w-i2c0"
			# Set meshtasticd MacAddressSource to 'end1' for lyra-ultra-w
			MTSetMacSrc "end1"
			# Download 'Luckfox Ultra' 2W hat config for lyra-ultra
			curl -fsSL https://raw.githubusercontent.com/meshtastic/firmware/607b631114349234b8859c2da0d0f553b3d344f3/bin/config.d/lora-lyra-ultra_2w.yaml \
				-o /etc/meshtasticd/config.d/lora-lyra-ultra_2w.yaml
			;;
		luckfox-lyra-zero-w)
			# Enable luckfox-lyra-zero-w-spi0-1cs-spidev overlay
			EnableKernelDTOverlay "luckfox-lyra-zero-w-spi0-1cs-spidev"
			;;
		luckfox-pico-max)
			# Set meshtasticd MacAddressSource to 'eth0' for pico-max
			MTSetMacSrc "eth0"
			;;
		luckfox-pico-mini)
			# Set meshtasticd MacAddressSource to 'eth0' for pico-mini
			MTSetMacSrc "eth0"
			# Copy femtofox config for pico-mini
			cp /etc/meshtasticd/available.d/femtofox/femtofox_SX1262_TCXO.yaml /etc/meshtasticd/config.d/
			;;
		# raspberry-pi-64bit
		rpi4b)
			# Setup devicetree overlay for SPI stuff
			# TODO Set meshtasticd MacAddressSource to 'eth0' for rpi4b
			# MTSetMacSrc "eth0"
			;;
		*)
			echo "No board-specific customizations for board: $BOARD"
			;;
	esac
	# Fix ownership for meshtasticd configs
	chown -R meshtasticd:meshtasticd /etc/meshtasticd/config.d
} # BoardSpecific

Main "$@"
BoardSpecific "$@"
