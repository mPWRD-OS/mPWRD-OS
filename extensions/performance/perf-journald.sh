#!/usr/bin/env bash

function pre_umount_final_image__perf_journald_apply() {
	mkdir -p "${MOUNT}/etc/systemd/journald.conf.d"

	# Override journald defaults for low-memory systems:
	# - cap persistent/runtime journal size to 8M each
	# - keep 16M free on disk to avoid starving package/system writes
	# - write less frequently (5m sync interval) to reduce I/O churn
	# - disable syslog forwarding and keep bounded rate limiting
	cat > "${MOUNT}/etc/systemd/journald.conf.d/99-lowmem-journal.conf" <<- 'EOF_JOURNAL'
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
	chmod 0644 "${MOUNT}/etc/systemd/journald.conf.d/99-lowmem-journal.conf"
	return 0
}
