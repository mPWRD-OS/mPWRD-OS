#!/usr/bin/env bash

function pre_umount_final_image__perf_sysctl_apply() {
	local vfs_cache_pressure="${PERF_VFS_CACHE_PRESSURE:-300}"
	local min_free_kbytes="${PERF_MIN_FREE_KBYTES:-3072}"

	mkdir -p "${MOUNT}/etc/sysctl.d"
	cat > "${MOUNT}/etc/sysctl.d/99-perf-lowmem.conf" <<- EOF_SYSCTL
	# Performance low-memory tuning for Luckfox Pico Mini (64MB class)
	# Prefer swapping anonymous pages under pressure (higher than typical defaults).
	vm.swappiness=100
	# Reclaim VFS cache more aggressively than default to keep free memory available.
	vm.vfs_cache_pressure=${vfs_cache_pressure}
	# Swap in smaller chunks to reduce latency spikes on slow swap media.
	vm.page-cluster=0
	# If OOM occurs, kill allocating task directly instead of heuristic victim selection.
	vm.oom_kill_allocating_task=1
	# Disable transient watermark boosting behavior.
	vm.watermark_boost_factor=0
	# Start writeback earlier than defaults to smooth bursty flush behavior.
	vm.dirty_background_ratio=2
	# Cap dirty cache growth lower than defaults to avoid long flush stalls.
	vm.dirty_ratio=6
	# Expire dirty data sooner than defaults.
	vm.dirty_expire_centisecs=1500
	# Trigger periodic writeback more frequently than defaults.
	vm.dirty_writeback_centisecs=1000
	# Reserve minimum free pages for allocator headroom under pressure.
	vm.min_free_kbytes=${min_free_kbytes}
	EOF_SYSCTL
	chmod 0644 "${MOUNT}/etc/sysctl.d/99-perf-lowmem.conf"
	return 0
}
