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
		pipx_g=true
		;;
	bookworm)
		pipx_g=false
		;;
	resolute)
		pipx_g=true
		;;
	noble)
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
	# meshtasticd can't currently be installed via the `meshtasticd` Extension
	# due to a race condition with the gpio group when installing before family-tweaks.
	InstallAptPkg "meshtasticd"
	# Same story with i2c-tools. Race condition with i2c group in family-tweaks.
	InstallAptPkg "i2c-tools"
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
	BoardSpecific "$@"
	apt-get clean && rm -rf /var/lib/apt/lists/*
	CompileDTBO
} # Main

ApplyFSOverlay() {
	# Copy overlay files to their destinations
	# replacing existing files
	cp -r /tmp/overlay/fs/* /
} # ApplyFSOverlay

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
} # EnableKernelDTOverlay


MTSetMacSrc() {
	iface_name="$1"
	# Set the General.MACAddressSource to $iface_name
	# for meshtasticd (/etc/meshtasticd/config.yaml)
	sed -i "s/^#\?  MACAddressSource: .*/  MACAddressSource: $iface_name/" /etc/meshtasticd/config.yaml
} # MTSetMacSrc

BoardSpecific() {
	# Note: Board specific customizations may also be added via Extensions
	# See extensions/ directory
	case $BOARD in
		ebyte-ecb41-pge)
			# Enable ebyte-ecb41-pge-spi0-1cs-spidev overlay
			EnableUserDTOverlay "ebyte-ecb41-pge-spi0-1cs-spidev"
			# Set meshtasticd MacAddressSource to 'end0' for ebyte-ecb41-pge
			MTSetMacSrc "end0"
			;;
		forlinx-ok3506-s12)
			# Enable forlinx-ok3506-s12-spi0-1cs-spidev overlay
			EnableKernelDTOverlay "forlinx-ok3506-s12-spi0-1cs-spidev"
			# Set meshtasticd MacAddressSource to 'end0' for forlinx-ok3506-s12
			MTSetMacSrc "end0"
			;;
		luckfox-lyra-plus)
			# Enable luckfox-lyra-plus-spi0-1cs_rmio13-spidev overlay
			EnableKernelDTOverlay "luckfox-lyra-plus-spi0-1cs_rmio13-spidev"
			# Set meshtasticd MacAddressSource to 'end1' for lyra-plus
			MTSetMacSrc "end1"
			# Download waveshare pico config for lyra-plus
			curl -fsSL https://raw.githubusercontent.com/meshtastic/firmware/refs/tags/v2.7.22.96dd647/bin/config.d/lora-lyra-ws-raspberry-pi-pico-hat.yaml \
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
			curl -fsSL https://raw.githubusercontent.com/meshtastic/firmware/refs/tags/v2.7.22.96dd647/bin/config.d/lora-lyra-ultra_2w.yaml \
				-o /etc/meshtasticd/config.d/lora-lyra-ultra_2w.yaml
			;;
		luckfox-lyra-zero-w)
			# Enable luckfox-lyra-zero-w-spi0-1cs-spidev overlay
			EnableKernelDTOverlay "luckfox-lyra-zero-w-spi0-1cs-spidev"
			;;
		luckfox-pico-max)
			# Set meshtasticd MacAddressSource to 'eth0' for pico-max
			MTSetMacSrc "eth0"
			# Download waveshare pico config for pico-max (from develop branch)
			curl -fsSL https://github.com/meshtastic/firmware/raw/466cc4cecddd11cd1bb0d0b166bd658d116832b3/bin/config.d/lora-luckfox-pico-max-ws-raspberry-pi-pico-hat.yaml \
				-o /etc/meshtasticd/config.d/lora-luckfox-pico-max-ws-raspberry-pi-pico-hat.yaml
			;;
		luckfox-pico-mini)
			# Set meshtasticd MacAddressSource to 'eth0' for pico-mini
			MTSetMacSrc "eth0"
			# Download femtofox config for pico-mini (directory changed upstream)
			curl -fsSL https://raw.githubusercontent.com/meshtastic/firmware/refs/tags/v2.7.22.96dd647/bin/config.d/lora-femtofox_SX1262_TCXO.yaml \
				-o /etc/meshtasticd/config.d/lora-femtofox_SX1262_TCXO.yaml
			;;
		# raspberry-pi-64bit
		rpi4b)
			# Set meshtasticd MacAddressSource to 'end0' for Raspberry Pi
			MTSetMacSrc "end0"
			;;
		*)
			echo "No board-specific customizations for board: $BOARD"
			;;
	esac
	# Fix ownership for meshtasticd configs
	chown -R meshtasticd:meshtasticd /etc/meshtasticd/config.d
} # BoardSpecific

Main "$@"
