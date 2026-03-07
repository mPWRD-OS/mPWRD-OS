#!/usr/bin/env bash

function pre_umount_final_image__perf_tmp_rootfs_apply() {
	if [[ ! -f "${MOUNT}/etc/fstab" ]]; then
		return 0
	fi

	# Armbian writes /tmp as tmpfs by default. Remove that entry so /tmp
	# falls back to the root filesystem and can use normal disk space.
	sed -Ei '/^[[:space:]]*tmpfs[[:space:]]+\/tmp[[:space:]]+tmpfs([[:space:]]|$)/d' \
		"${MOUNT}/etc/fstab"

	# Keep /tmp as the standard sticky world-writable directory on the rootfs.
	install -d -m 1777 "${MOUNT}/tmp"

	# armbian-zram-config mounts a zram filesystem on /tmp after local-fs.target.
	# When that happens, immediately unmount it so the plain rootfs-backed /tmp remains.
	install -d -m 0755 "${MOUNT}/etc/systemd/system/armbian-zram-config.service.d"
	cat > "${MOUNT}/etc/systemd/system/armbian-zram-config.service.d/no-tmp-zram.conf" <<-'EOF_TMP_ZRAM'
	[Service]
	ExecStartPost=/bin/sh -ec 'case "$(/usr/bin/findmnt -n -o SOURCE --target /tmp || true)" in /dev/zram*) /usr/bin/umount /tmp ;; esac'
	EOF_TMP_ZRAM
	chmod 0644 "${MOUNT}/etc/systemd/system/armbian-zram-config.service.d/no-tmp-zram.conf"

	return 0
}
