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

Main() {
	case $RELEASE in
		trixie)
			ApplyOverlay
			AddMeshtasticRepo_Debian_OBS
			InstallAptPkg "meshtasticd"
			InstallAptPkg "pipx"
			InstallPipxPkg "meshtastic"
			InstallPipxPkg "contact"
			CleanupApt
			;;
		bookworm)
			ApplyOverlay
			AddMeshtasticRepo_Debian_OBS
			InstallAptPkg "meshtasticd"
			InstallAptPkg "pipx"
			# pipx too old for global InstallPipxPkg on bookworm
			CleanupApt
			;;
		noble)
			ApplyOverlay
			AddMeshtasticRepo_Ubuntu_PPA
			InstallAptPkg "meshtasticd"
			InstallAptPkg "pipx"
			# pipx too old for global InstallPipxPkg on noble
			CleanupApt
			;;
		*)
			echo "Unsupported mPWRD RELEASE: $RELEASE"
			exit 1
			;;
	esac
} # Main

ApplyOverlay() {
	# Copy overlay files to their destinations
	# replacing existing files
	cp -r /tmp/overlay/* /
} # ApplyOverlay

AddMeshtasticRepo_Debian_OBS() {
	export DEBIAN_FRONTEND=noninteractive
	export APT_LISTCHANGES_FRONTEND=none
	apt-get update
	apt-get --yes --force-yes --allow-unauthenticated \
		install gpg
	case $RELEASE in
		trixie)
			debian_slug="Debian_13"
			;;
		bookworm)
			debian_slug="Debian_12"
			;;
	esac
	echo "deb http://download.opensuse.org/repositories/network:/Meshtastic:/beta/$debian_slug/ /" | tee /etc/apt/sources.list.d/network:Meshtastic:beta.list
	curl -fsSL https://download.opensuse.org/repositories/network:Meshtastic:beta/$debian_slug/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/network_Meshtastic_beta.gpg > /dev/null
	apt-get update
} # AddMeshtasticRepo_Debian_OBS

AddMeshtasticRepo_Ubuntu_PPA() {
	export DEBIAN_FRONTEND=noninteractive
	export APT_LISTCHANGES_FRONTEND=none
	# apt-get update
	# apt-get --yes --force-yes --allow-unauthenticated \
	# 	install software-properties-common
	add-apt-repository --yes ppa:meshtastic/beta
	apt-get update
} # AddMeshtasticRepo_Ubuntu_PPA

InstallAptPkg() {
	PKGSPEC="$1"
	# Install package via apt-get
	echo "APT: Installing ${PKGSPEC}..."
	export DEBIAN_FRONTEND=noninteractive
	export APT_LISTCHANGES_FRONTEND=none
	apt-get --yes --force-yes --allow-unauthenticated \
		install "${PKGSPEC}"
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

BoardSpecific() {
	case $BOARD in
		luckfox-pico-mini)
			# Copy femtofox config for pico-mini
			cp /etc/meshtasticd/available.d/femtofox/femtofox_SX1262_TCXO.yaml /etc/meshtasticd/config.d/
			# Insert terrible things here 😈
			;;
		# raspberry-pi-64bit
		rpi4b)
			# Setup devicetree overlay for SPI stuff
			;;
		*)
			echo "No board-specific customizations for board: $BOARD"
			;;
	esac
} # BoardSpecific

Main "$@"
BoardSpecific "$@"
