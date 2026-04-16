# shellcheck shell=bash
#
# Unblock rfkill at boot by creating a systemd service that runs 'rfkill unblock all'
# Inspired by: https://github.com/armbian/build/blob/main/config/sources/families/bcm2711.conf
# Disable with:
#  systemctl disable unblock-rfkill.service
#  rfkill block all
#
function pre_install_distribution_specific__unblock_rfkill() {
	# Create a systemd service to unblock rfkill
	cat > "${SDCARD}/etc/systemd/system/unblock-rfkill.service" <<- EOT
	[Unit]
	Description=Unblock rfkill
	Before=network-pre.target NetworkManager.service bluetooth.service
	Wants=network-pre.target

	[Service]
	Type=oneshot
	ExecStart=/usr/sbin/rfkill unblock all
	RemainAfterExit=true

	[Install]
	WantedBy=network-pre.target
	EOT
	# Enable the service to run at boot
	display_alert "Enabling unblock-rfkill service" "$BOARD" "info"
	chroot_sdcard systemctl enable unblock-rfkill.service
}
