#!/usr/bin/env bash

# Compatibility wrapper extension.
# Prefer enabling the modular extension set directly:
# - perf-journald
# - perf-sysctl
# - perf-apt
# - perf-defaults
# - perf-fstab-noatime

source "$(dirname "${BASH_SOURCE[0]}")/perf-journald.sh"
source "$(dirname "${BASH_SOURCE[0]}")/perf-sysctl.sh"
source "$(dirname "${BASH_SOURCE[0]}")/perf-apt.sh"
source "$(dirname "${BASH_SOURCE[0]}")/perf-defaults.sh"
source "$(dirname "${BASH_SOURCE[0]}")/perf-fstab-noatime.sh"

function pre_umount_final_image__perf_lowram_apply() {
	pre_umount_final_image__perf_journald_apply
	pre_umount_final_image__perf_sysctl_apply
	pre_umount_final_image__perf_apt_apply
	pre_umount_final_image__perf_defaults_apply
	pre_umount_final_image__perf_fstab_noatime_apply
	return 0
}
