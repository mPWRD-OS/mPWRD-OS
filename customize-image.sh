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
			AddMeshtasticRepo_Debian_OBS
			InstallMeshtasticd
			InstallPythonPipx
			InstallMeshtasticCLI
			CleanupApt
			;;
		bookworm)
			AddMeshtasticRepo_Debian_OBS
			InstallMeshtasticd
			InstallPythonPipx
			# pipx too old for global MeshtasticCLI install on bookworm
			CleanupApt
			;;
		noble)
			AddMeshtasticRepo_Ubuntu_PPA
			InstallMeshtasticd
			InstallPythonPipx
			# pipx too old for global MeshtasticCLI install on noble
			CleanupApt
			;;
		*)
			echo "Unsupported mPWRD RELEASE: $RELEASE"
			exit 1
			;;
	esac
} # Main

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

InstallMeshtasticd() {
	export DEBIAN_FRONTEND=noninteractive
	export APT_LISTCHANGES_FRONTEND=none
	apt-get --yes --force-yes --allow-unauthenticated \
		install meshtasticd
} # InstallMeshtasticd

InstallPythonPipx() {
	# Install pipx for installing Meshtastic CLI (and other python apps)
	export DEBIAN_FRONTEND=noninteractive
	export APT_LISTCHANGES_FRONTEND=none
	apt-get --yes --force-yes --allow-unauthenticated \
		install pipx
} # InstallPythonPipx

InstallMeshtasticCLI() {
	# Install Meshtastic CLI via pipx
	pipx ensurepath --quiet --global
	pipx install --global meshtastic
	# --global flag requires pipx 1.5.0 or newer
} # InstallMeshtasticCLI

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
