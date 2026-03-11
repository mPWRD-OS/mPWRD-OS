#!/usr/bin/env bash

function pre_umount_final_image__perf_tmp_rootfs_apply() {
	local MPWRD_TMP_DIR="/opt/tmp"
	if [[ ! -f "${MOUNT}/etc/fstab" ]]; then
		return 0
	fi

	# Armbian writes /tmp as tmpfs by default.
	# Remove that entry so /tmp uses the bind mount instead.
	sed -Ei '/^[[:space:]]*tmpfs[[:space:]]+\/tmp[[:space:]]+tmpfs([[:space:]]|$)/d' \
		"${MOUNT}/etc/fstab"

	# Create sticky world-writable directories
	install -d -m 1777 "${MOUNT}/tmp"
	install -d -m 1777 "${MOUNT}${MPWRD_TMP_DIR}"

	# Create a /tmp bind mount at /opt/tmp
	echo "${MPWRD_TMP_DIR} /tmp none bind 0 0" >> "${MOUNT}/etc/fstab"

	return 0
}
