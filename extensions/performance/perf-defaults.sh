#!/usr/bin/env bash

function pre_umount_final_image__perf_defaults_apply() {
	local rootfs="${MOUNT}"
	local zram_percentage="${PERF_ZRAM_PERCENTAGE:-75}"

	# ZRAM: set compressed zram sizing using either current
	# (ZRAM_PERCENTAGE) or legacy (PERCENTAGE) keys.
	if [[ -f "${rootfs}/etc/default/armbian-zram-config" ]]; then
		if grep -q '^ZRAM_PERCENTAGE=' "${rootfs}/etc/default/armbian-zram-config"; then
			sed -i "s/^ZRAM_PERCENTAGE=.*/ZRAM_PERCENTAGE=${zram_percentage}/" "${rootfs}/etc/default/armbian-zram-config"
		elif grep -q '^PERCENTAGE=' "${rootfs}/etc/default/armbian-zram-config"; then
			sed -i "s/^PERCENTAGE=.*/PERCENTAGE=${zram_percentage}/" "${rootfs}/etc/default/armbian-zram-config"
		else
			printf '\nZRAM_PERCENTAGE=%s\n' "${zram_percentage}" >> "${rootfs}/etc/default/armbian-zram-config"
		fi
	fi

	# PAM: ensure pam_systemd session integration stays enabled for correct
	# session tracking/logind behavior on login shells.
	if [[ -f "${rootfs}/etc/pam.d/common-session" ]]; then
		sed -i -E 's/^#\s*(session[[:space:]]+optional[[:space:]]+pam_systemd\.so.*)$/\1/' \
			"${rootfs}/etc/pam.d/common-session" || true
	fi

	return 0
}
