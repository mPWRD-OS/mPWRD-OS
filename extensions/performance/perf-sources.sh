#!/usr/bin/env bash

# Build-time source profile manager:
# 1) Preserve upstream active sources as *.full.disabled snapshots.
# 2) Derive slim active sources from those upstream snapshots.
# 3) Preserve derived slim sources as *.slim.disabled snapshots.
#
# This keeps "full" profiles aligned with upstream content on each build,
# while still shipping a low-overhead default active profile.

function __perf_sources_make_armbian_slim() {
	local in_file="$1"
	local out_file="$2"
	local tmp_file
	tmp_file="$(mktemp)"

	awk '
	/^Components:[[:space:]]*/ {
		line = $0
		sub(/^Components:[[:space:]]*/, "", line)
		n = split(line, tok, /[[:space:]]+/)
		out = ""
		for (i = 1; i <= n; i++) {
			if (tok[i] == "") continue
			if (tok[i] ~ /-desktop$/) continue
			out = (out == "" ? tok[i] : out " " tok[i])
		}
		if (out == "") {
			print "perf-sources: armbian Components became empty after slimming" > "/dev/stderr"
			exit 10
		}
		print "Components: " out
		next
	}
	{ print }
	' "${in_file}" > "${tmp_file}"

	install -m 0644 "${tmp_file}" "${out_file}"
	rm -f "${tmp_file}"
	return 0
}

function __perf_sources_make_debian_slim() {
	local in_file="$1"
	local out_file="$2"
	local tmp_file
	tmp_file="$(mktemp)"

	awk '
	/^Suites:[[:space:]]*/ {
		line = $0
		sub(/^Suites:[[:space:]]*/, "", line)
		n = split(line, tok, /[[:space:]]+/)
		out = ""
		for (i = 1; i <= n; i++) {
			if (tok[i] == "") continue
			if (tok[i] ~ /backports$/) continue
			out = (out == "" ? tok[i] : out " " tok[i])
		}
		if (out == "") {
			print "perf-sources: debian Suites became empty after slimming" > "/dev/stderr"
			exit 20
		}
		print "Suites: " out
		next
	}
	/^Components:[[:space:]]*/ {
		print "Components: main"
		next
	}
	{ print }
	' "${in_file}" > "${tmp_file}"

	install -m 0644 "${tmp_file}" "${out_file}"
	rm -f "${tmp_file}"
	return 0
}

function pre_umount_final_image__perf_sources_apply() {
	local rootfs="${MOUNT}"
	local sources_dir="${rootfs}/etc/apt/sources.list.d"
	local armbian_active="${sources_dir}/armbian.sources"
	local debian_active="${sources_dir}/debian.sources"
	local armbian_full="${sources_dir}/armbian.sources.full.disabled"
	local debian_full="${sources_dir}/debian.sources.full.disabled"
	local armbian_slim="${sources_dir}/armbian.sources.slim.disabled"
	local debian_slim="${sources_dir}/debian.sources.slim.disabled"

	# If upstream source files are absent, do nothing.
	[[ -f "${armbian_active}" ]] || return 0
	[[ -f "${debian_active}" ]] || return 0

	# Preserve upstream active profiles as full snapshots.
	install -m 0644 "${armbian_active}" "${armbian_full}"
	install -m 0644 "${debian_active}" "${debian_full}"

	# Derive slim active profiles from full snapshots.
	__perf_sources_make_armbian_slim "${armbian_full}" "${armbian_active}"
	__perf_sources_make_debian_slim "${debian_full}" "${debian_active}"

	# Preserve derived slim profiles as disabled snapshots.
	install -m 0644 "${armbian_active}" "${armbian_slim}"
	install -m 0644 "${debian_active}" "${debian_slim}"

	return 0
}
