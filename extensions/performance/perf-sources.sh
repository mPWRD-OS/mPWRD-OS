#!/usr/bin/env bash

# Build-time APT source profile normalization for low-memory images.
#
# Behavior:
# - Preserve upstream-provided source manifests as immutable snapshots:
#   - /etc/apt/sources.list.d/armbian.sources.upstream
#   - /etc/apt/sources.list.d/debian.sources.upstream
# - Derive slim active manifests from those upstream snapshots.
#
# Slim policy (applied uniformly to all processed .sources files):
# - Remove any Components token ending in "-desktop"
#   (for example, "trixie-desktop"), keep remaining components unchanged.
# - Remove any Suites token containing "backports"
#   (for example, "trixie-backports").
# - Enforce "Components: main" when non-main components are present,
#   so contrib, non-free, and non-free-firmware are excluded.
#
# Rationale:
# - Keeps a verbatim upstream baseline for audit/rollback.
# - Applies deterministic, reproducible slimming without hardcoding sources.
function __perf_sources_make_slim() {
	local in_file="$1"
	local out_file="$2"
	local tmp_file
	tmp_file="$(mktemp)"
	trap 'rm -f "${tmp_file}"' RETURN

	awk '
	/^Suites:[[:space:]]*/ {
		line = $0
		sub(/^Suites:[[:space:]]*/, "", line)
		n = split(line, tok, /[[:space:]]+/)
		out = ""
		for (i = 1; i <= n; i++) {
			if (tok[i] == "") continue
			if (tok[i] ~ /backports/) continue
			out = (out == "" ? tok[i] : out " " tok[i])
		}
		if (out == "") {
			print "perf-sources: Suites became empty after slimming" > "/dev/stderr"
			exit 20
		}
		print "Suites: " out
		next
	}
	/^Components:[[:space:]]*/ {
		line = $0
		sub(/^Components:[[:space:]]*/, "", line)
		n = split(line, tok, /[[:space:]]+/)
		out = ""
		force_main = 0
		for (i = 1; i <= n; i++) {
			if (tok[i] == "") continue
			if (tok[i] ~ /-desktop$/) continue
			if (tok[i] == "contrib" || tok[i] ~ /^non-free(-firmware)?$/) {
				force_main = 1
				continue
			}
			out = (out == "" ? tok[i] : out " " tok[i])
		}
		if (force_main == 1) {
			print "Components: main"
			next
		}
		if (out == "") {
			print "perf-sources: Components became empty after slimming" > "/dev/stderr"
			exit 10
		}
		print "Components: " out
		next
	}
	{ print }
	' "${in_file}" > "${tmp_file}"
	local rc=$?
	if [[ ${rc} -ne 0 ]]; then
		return "${rc}"
	fi

	install -m 0644 "${tmp_file}" "${out_file}" || return $?
	return 0
}

function pre_umount_final_image__700_perf_sources_apply() {
	local sources_dir="${MOUNT}/etc/apt/sources.list.d"
	local armbian_active="${sources_dir}/armbian.sources"
	local debian_active="${sources_dir}/debian.sources"
	local armbian_upstream="${armbian_active}.upstream"
	local debian_upstream="${debian_active}.upstream"

	# Process each active source file independently if present.
	if [[ -f "${armbian_active}" ]]; then
		# Preserve upstream active profile as an upstream snapshot.
		if [[ ! -f "${armbian_upstream}" ]]; then
			install -m 0644 "${armbian_active}" "${armbian_upstream}"
		fi
		# Derive slim active profile from upstream snapshot.
		__perf_sources_make_slim "${armbian_upstream}" "${armbian_active}"
	fi

	if [[ -f "${debian_active}" ]]; then
		# Preserve upstream active profile as an upstream snapshot.
		if [[ ! -f "${debian_upstream}" ]]; then
			install -m 0644 "${debian_active}" "${debian_upstream}"
		fi
		# Derive slim active profile from upstream snapshot.
		__perf_sources_make_slim "${debian_upstream}" "${debian_active}"
	fi

	return 0
}
