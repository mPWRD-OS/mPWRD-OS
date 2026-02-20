#!/usr/bin/env bash

# Compatibility wrapper extension.
# Prefer enabling the modular extension set directly:
# - luckfox-perf-journald
# - luckfox-perf-sysctl
# - luckfox-perf-apt
# - luckfox-perf-defaults
# - luckfox-perf-fstab-noatime
# - luckfox-perf-terminal

source "$(dirname "${BASH_SOURCE[0]}")/luckfox-perf-journald.sh"
source "$(dirname "${BASH_SOURCE[0]}")/luckfox-perf-sysctl.sh"
source "$(dirname "${BASH_SOURCE[0]}")/luckfox-perf-apt.sh"
source "$(dirname "${BASH_SOURCE[0]}")/luckfox-perf-defaults.sh"
source "$(dirname "${BASH_SOURCE[0]}")/luckfox-perf-fstab-noatime.sh"
source "$(dirname "${BASH_SOURCE[0]}")/luckfox-perf-terminal.sh"

function pre_umount_final_image__luckfox_perf_lowram_apply() {
	pre_umount_final_image__luckfox_perf_journald_apply
	pre_umount_final_image__luckfox_perf_sysctl_apply
	pre_umount_final_image__luckfox_perf_apt_apply
	pre_umount_final_image__luckfox_perf_defaults_apply
	pre_umount_final_image__luckfox_perf_fstab_noatime_apply
	pre_umount_final_image__luckfox_perf_terminal_apply
	return 0
}

