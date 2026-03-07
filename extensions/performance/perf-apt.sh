#!/usr/bin/env bash

function pre_umount_final_image__perf_apt_apply() {
	mkdir -p "${MOUNT}/etc/apt/apt.conf.d"

	# APT tuning for low-RAM images; transport/cache + low-RAM knobs.
	cat > "${MOUNT}/etc/apt/apt.conf.d/90-perf-apt.conf" <<- 'EOF_APT_PERF'
	// Performance apt transport/cache tuning for very low RAM systems.
	Acquire::Retries "1";
	Acquire::http::Timeout "8";
	Acquire::https::Timeout "12";
	Acquire::Queue-Mode "access";
	Acquire::http::No-Cache "true";
	Acquire::http::Pipeline-Depth "0";
	// perf-sources ships *.upstream source snapshots; ignore them silently.
	Dir::Ignore-Files-Silently:: "\.upstream$";
	Dir::Cache::pkgcache "";
	Dir::Cache::srcpkgcache "";

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
	EOF_APT_PERF

	chmod 0644 \
		"${MOUNT}/etc/apt/apt.conf.d/90-perf-apt.conf"
	return 0
}
