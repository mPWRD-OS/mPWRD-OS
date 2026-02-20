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

	return 0
}
