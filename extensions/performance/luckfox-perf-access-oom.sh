#!/usr/bin/env bash

# Optional service-level hardening for OOM survival and Meshtastic responsiveness.
# Keep separate from core low-RAM tuning so service tuning remains opt-in.

function pre_umount_final_image__luckfox_perf_access_oom_apply() {
	if [[ "${BOARD:-}" != "luckfox-pico-mini" ]]; then
		return 0
	fi

	local rootfs="${MOUNT}"
	display_alert "Extension: ${EXTENSION}: applying" "${rootfs}" "info"

	mkdir -p "${rootfs}/etc/systemd/system/ssh.service.d" \
		"${rootfs}/etc/systemd/system/getty@.service.d" \
		"${rootfs}/etc/systemd/system/serial-getty@.service.d" \
		"${rootfs}/etc/systemd/system/meshtasticd.service.d"

	cat > "${rootfs}/etc/systemd/system/ssh.service.d/10-oom-protect.conf" <<- 'EOF_SSH_OOM'
	[Service]
	OOMScoreAdjust=-900
	EOF_SSH_OOM

	cat > "${rootfs}/etc/systemd/system/getty@.service.d/10-oom-protect.conf" <<- 'EOF_GETTY_OOM'
	[Service]
	OOMScoreAdjust=-850
	EOF_GETTY_OOM

	cat > "${rootfs}/etc/systemd/system/serial-getty@.service.d/10-oom-protect.conf" <<- 'EOF_SERIAL_OOM'
	[Service]
	OOMScoreAdjust=-850
	EOF_SERIAL_OOM

	cat > "${rootfs}/etc/systemd/system/meshtasticd.service.d/10-runtime-priority.conf" <<- 'EOF_MESHTASTICD'
	[Service]
	Nice=-5
	OOMScoreAdjust=-500
	CPUWeight=500
	IOSchedulingClass=2
	IOSchedulingPriority=0
	LimitNOFILE=4096
	EOF_MESHTASTICD

	chmod 0644 \
		"${rootfs}/etc/systemd/system/ssh.service.d/10-oom-protect.conf" \
		"${rootfs}/etc/systemd/system/getty@.service.d/10-oom-protect.conf" \
		"${rootfs}/etc/systemd/system/serial-getty@.service.d/10-oom-protect.conf" \
		"${rootfs}/etc/systemd/system/meshtasticd.service.d/10-runtime-priority.conf"

	return 0
}

