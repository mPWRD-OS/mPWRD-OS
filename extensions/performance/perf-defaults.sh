#!/usr/bin/env bash

function pre_umount_final_image__perf_defaults_apply() {
	local rootfs="${MOUNT}"
	local zram_percentage="${PERF_ZRAM_PERCENTAGE:-75}"

	if [[ -f "${rootfs}/etc/default/armbian-zram-config" ]]; then
		sed -i 's/^SWAP=.*/SWAP=true/' "${rootfs}/etc/default/armbian-zram-config" || true
		if grep -q '^ZRAM_PERCENTAGE=' "${rootfs}/etc/default/armbian-zram-config"; then
			sed -i "s/^ZRAM_PERCENTAGE=.*/ZRAM_PERCENTAGE=${zram_percentage}/" "${rootfs}/etc/default/armbian-zram-config"
		elif grep -q '^PERCENTAGE=' "${rootfs}/etc/default/armbian-zram-config"; then
			sed -i "s/^PERCENTAGE=.*/PERCENTAGE=${zram_percentage}/" "${rootfs}/etc/default/armbian-zram-config"
		else
			printf '\nZRAM_PERCENTAGE=%s\n' "${zram_percentage}" >> "${rootfs}/etc/default/armbian-zram-config"
		fi
	fi

	if [[ -f "${rootfs}/etc/default/cpufrequtils" ]]; then
		if grep -q '^GOVERNOR=' "${rootfs}/etc/default/cpufrequtils"; then
			sed -i 's/^GOVERNOR=.*/GOVERNOR=ondemand/' "${rootfs}/etc/default/cpufrequtils"
		else
			printf '\nGOVERNOR=ondemand\n' >> "${rootfs}/etc/default/cpufrequtils"
		fi
	fi

	if [[ -f "${rootfs}/etc/pam.d/common-session" ]]; then
		sed -i -E 's/^#\s*(session[[:space:]]+optional[[:space:]]+pam_systemd\.so.*)$/\1/' \
			"${rootfs}/etc/pam.d/common-session" || true
	fi

	return 0
}
