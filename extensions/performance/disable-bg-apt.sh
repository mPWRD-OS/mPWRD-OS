#
# Disable background apt activity in the final image.
#
function pre_umount_final_image__700_disable_bg_apt() {
	display_alert "Extension: ${EXTENSION}" "Disable background apt tasks" "info"

	# Disable/mask apt timers and services in systemd-based images.
	if chroot_sdcard command -v systemctl >/dev/null 2>&1; then
		chroot_sdcard systemctl disable apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1 || true
		chroot_sdcard systemctl mask apt-daily.timer apt-daily-upgrade.timer apt-daily.service apt-daily-upgrade.service >/dev/null 2>&1 || true
	fi

	# Disable cron entrypoints if present.
	chroot_sdcard chmod -x /usr/lib/armbian/armbian-apt-updates >/dev/null 2>&1 || true
	chroot_sdcard chmod -x /etc/cron.daily/apt-compat >/dev/null 2>&1 || true

	# Ensure apt periodic behavior stays disabled.
	mkdir -p "${SDCARD}/etc/apt/apt.conf.d"
	cat > "${SDCARD}/etc/apt/apt.conf.d/99-disable-periodic-updates" <<'EOF'
APT::Periodic::Enable "0";
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Unattended-Upgrade "0";
EOF
}
