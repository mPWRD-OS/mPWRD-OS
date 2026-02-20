#!/usr/bin/env bash

function pre_umount_final_image__perf_sysctl_apply() {
	if [[ "${BOARD:-}" != "luckfox-pico-mini" ]]; then
		return 0
	fi

	local rootfs="${MOUNT}"
	local vfs_cache_pressure="${PERF_VFS_CACHE_PRESSURE:-300}"
	local min_free_kbytes="${PERF_MIN_FREE_KBYTES:-3072}"

	mkdir -p "${rootfs}/etc/sysctl.d"
	cat > "${rootfs}/etc/sysctl.d/99-perf-lowmem.conf" <<- EOF_SYSCTL
	# Performance low-memory tuning for Luckfox Pico Mini (64MB class)
	vm.swappiness=100
	vm.vfs_cache_pressure=${vfs_cache_pressure}
	vm.page-cluster=0
	vm.overcommit_memory=2
	vm.overcommit_ratio=50
	vm.oom_kill_allocating_task=1
	vm.watermark_boost_factor=0
	vm.dirty_background_ratio=2
	vm.dirty_ratio=6
	vm.dirty_expire_centisecs=1500
	vm.dirty_writeback_centisecs=1000
	vm.min_free_kbytes=${min_free_kbytes}
	EOF_SYSCTL
	chmod 0644 "${rootfs}/etc/sysctl.d/99-perf-lowmem.conf"
	return 0
}

