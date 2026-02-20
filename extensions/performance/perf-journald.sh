#!/usr/bin/env bash

function pre_umount_final_image__perf_journald_apply() {
	if [[ "${BOARD:-}" != "luckfox-pico-mini" ]]; then
		return 0
	fi

	local rootfs="${MOUNT}"
	mkdir -p "${rootfs}/etc/systemd/journald.conf.d"
	cat > "${rootfs}/etc/systemd/journald.conf.d/99-lowmem-journal.conf" <<- 'EOF_JOURNAL'
	[Journal]
	SystemMaxUse=8M
	RuntimeMaxUse=8M
	SystemKeepFree=16M
	Compress=yes
	SyncIntervalSec=5m
	RateLimitIntervalSec=30s
	RateLimitBurst=200
	ForwardToSyslog=no
	EOF_JOURNAL
	chmod 0644 "${rootfs}/etc/systemd/journald.conf.d/99-lowmem-journal.conf"
	return 0
}

