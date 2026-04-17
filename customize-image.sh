#!/bin/bash
set -euo pipefail

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
# shellcheck disable=SC2034 # Armbian passes this argument; this script does not currently branch on it.
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
	apt-get clean && rm -rf /var/lib/apt/lists/*
	CompileDTBO
} # Main

ApplyFSOverlay() {
	# Copy overlay files to their destinations
	# replacing existing files
	cp -r /tmp/overlay/fs/* /
} # ApplyFSOverlay

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



Main "$@"
