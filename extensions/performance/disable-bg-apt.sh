#
# Disable background apt activity in the final image.
#
function pre_umount_final_image__700_disable_bg_apt() {
	display_alert "Extension: ${EXTENSION}" "Disable background apt tasks" "info"

	# pre_umount_final_image runs in "image" stage, so target MOUNT/chroot_mount.
	if [[ -z "${MOUNT:-}" || ! -d "${MOUNT}" ]]; then
		display_alert "Extension: ${EXTENSION}" "MOUNT is unavailable; skipping disable-bg-apt" "wrn"
		return 0
	fi

	# Disable/mask apt timers and services in systemd-based images.
	if chroot_mount command -v systemctl >/dev/null 2>&1; then
		chroot_mount systemctl disable apt-daily.timer apt-daily-upgrade.timer || true
		chroot_mount systemctl mask apt-daily.timer apt-daily-upgrade.timer apt-daily.service apt-daily-upgrade.service || true
	fi
	mkdir -p "${MOUNT}/etc/systemd/system"
	ln -sf /dev/null "${MOUNT}/etc/systemd/system/apt-daily.timer"
	ln -sf /dev/null "${MOUNT}/etc/systemd/system/apt-daily-upgrade.timer"
	ln -sf /dev/null "${MOUNT}/etc/systemd/system/apt-daily.service"
	ln -sf /dev/null "${MOUNT}/etc/systemd/system/apt-daily-upgrade.service"
	rm -f "${MOUNT}/etc/systemd/system/timers.target.wants/apt-daily.timer"
	rm -f "${MOUNT}/etc/systemd/system/timers.target.wants/apt-daily-upgrade.timer"

	# Disable cron entrypoints if present.
	chroot_mount chmod -x /usr/lib/armbian/armbian-apt-updates || true
	chroot_mount chmod -x /etc/cron.daily/apt-compat || true
	chroot_mount rm -f /etc/cron.d/armbian-updates || true

	# Ensure apt periodic behavior stays disabled.
	mkdir -p "${MOUNT}/etc/apt/apt.conf.d"
	cat > "${MOUNT}/etc/apt/apt.conf.d/99-disable-periodic-updates" <<'EOF'
APT::Periodic::Enable "0";
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::Unattended-Upgrade "0";
APT::Periodic::AutocleanInterval "0";
EOF
}
