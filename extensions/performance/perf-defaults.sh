#!/usr/bin/env bash

function pre_umount_final_image__perf_defaults_apply() {
	local rootfs="${MOUNT}"
	# Luckfox Pico Mini (RV1103, 64MB RAM) is highly sensitive to SD-backed
	# swap latency (no UHS path). A larger zram pool keeps more pressure in
	# compressed RAM before hitting /swapfile. Rebooted A/B on this board
	# showed ~16% lower forced-memory runtime at 75% vs 50%.
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
