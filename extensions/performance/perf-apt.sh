#!/usr/bin/env bash

function pre_umount_final_image__perf_apt_apply() {
	if [[ "${BOARD:-}" != "luckfox-pico-mini" ]]; then
		return 0
	fi

	local rootfs="${MOUNT}"
	mkdir -p "${rootfs}/etc/apt/apt.conf.d" "${rootfs}/etc/dpkg/dpkg.cfg.d"

	# Layer 1: transport + background-behavior tuning.
	# These are connection/retry/timeouts and periodic activity controls.
	cat > "${rootfs}/etc/apt/apt.conf.d/90-perf-apt.conf" <<- 'EOF_APT_PERF'
	// Performance apt transport/cache tuning for very low RAM systems.
	Acquire::ForceIPv4 "true";
	Acquire::Retries "1";
	Acquire::http::Timeout "8";
	Acquire::https::Timeout "12";
	Acquire::Queue-Mode "access";
	Acquire::http::No-Cache "true";
	Acquire::http::Pipeline-Depth "0";
	APT::Periodic::Update-Package-Lists "0";
	APT::Periodic::Unattended-Upgrade "0";
	APT::Periodic::AutocleanInterval "0";
	Dir::Cache::pkgcache "";
	Dir::Cache::srcpkgcache "";
	EOF_APT_PERF

	# Layer 2: low-memory survival knobs.
	# Kept separate from transport knobs so each layer can be reasoned about and adjusted independently.
	cat > "${rootfs}/etc/apt/apt.conf.d/99-perf-lowram.conf" <<- 'EOF_APT_LOWRAM'
	// Low-RAM apt survival profile.
	Acquire::IndexTargets::deb::Contents-deb::DefaultEnabled "false";
	Acquire::PDiffs "false";
	Acquire::GzipIndexes "true";
	APT::Keep-Downloaded-Packages "true";
	Binary::apt::APT::Keep-Downloaded-Packages "true";
	Binary::apt-get::APT::Keep-Downloaded-Packages "true";
	Dpkg::Progress-Fancy "0";
	Dpkg::Use-Pty "0";
	APT::Get::List-Cleanup "true";
	APT::Cache-Start "16777216";
	APT::Cache-Grow "1048576";
	EOF_APT_LOWRAM

	cat > "${rootfs}/etc/dpkg/dpkg.cfg.d/99unsafe-io" <<- 'EOF_DPKG'
	# Faster package unpack/configure at the cost of less fsync safety.
	force-unsafe-io
	EOF_DPKG

	chmod 0644 \
		"${rootfs}/etc/apt/apt.conf.d/90-perf-apt.conf" \
		"${rootfs}/etc/apt/apt.conf.d/99-perf-lowram.conf" \
		"${rootfs}/etc/dpkg/dpkg.cfg.d/99unsafe-io"
	return 0
}
