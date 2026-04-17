function extension_finish_config__install_kernel_headers_for_aic8800dc_dkms() {

	if [[ "${KERNEL_HAS_WORKING_HEADERS}" != "yes" ]]; then
		display_alert "Kernel version has no working headers package" "skipping aic8800dc dkms for kernel v${KERNEL_MAJOR_MINOR}" "warn"
		return 0
	fi
	declare -g INSTALL_HEADERS="yes"
	display_alert "Forcing INSTALL_HEADERS=yes; for use with aic8800dc dkms" "${EXTENSION}" "debug"
}

function post_install_kernel_debs__install_aic8800dc_dkms_package() {

	if linux-version compare "${KERNEL_MAJOR_MINOR}" ge 6.20; then
		display_alert "Kernel version is too recent" "skipping aic8800dc dkms for kernel v${KERNEL_MAJOR_MINOR}" "warn"
		return 0
	fi
	[[ "${INSTALL_HEADERS}" != "yes" ]] || [[ "${KERNEL_HAS_WORKING_HEADERS}" != "yes" ]] && return 0
	api_url="https://api.github.com/repos/vidplace7/aic8800d80/releases/latest"
	# latest_version=$(curl -s "${api_url}" | jq -r '.tag_name')
	# aic8800dc_firmware_url="https://github.com/vidplace7/aic8800d80/releases/download/${latest_version}/aic8800-firmware_${latest_version}_all.deb"
	# aic8800dc_usb_url="https://github.com/vidplace7/aic8800d80/releases/download/${latest_version}/aic8800-usb-dkms_${latest_version}_all.deb"
    aic8800dc_firmware_url="https://github.com/vidplace7/aic8800d80/releases/download/deb-testing/aic8800-firmware_5.0+git-1_all.deb"
    aic8800dc_usb_url="https://github.com/vidplace7/aic8800d80/releases/download/deb-testing/aic8800-usb-dkms_5.0+git-1_all.deb"
	if [[ "${GITHUB_MIRROR}" == "ghproxy" ]]; then
		ghproxy_header="https://ghfast.top/"
		aic8800dc_firmware_url=${ghproxy_header}${aic8800dc_firmware_url}
		aic8800dc_usb_url=${ghproxy_header}${aic8800dc_usb_url}
	fi
    # aic8800_dkms_file_name=aic8800-usb-dkms_${latest_version}_all.deb
    aic8800dc_dkms_file_name=aic8800-usb-dkms_5.0+git-1_all.deb
    # aic8800dc_firmware_file_name=aic8800-firmware_${latest_version}_all.deb
    aic8800dc_firmware_file_name=aic8800-firmware_5.0+git-1_all.deb
    use_clean_environment="yes" chroot_sdcard "wget ${aic8800dc_usb_url} -P /tmp"
	use_clean_environment="yes" chroot_sdcard "wget ${aic8800dc_firmware_url} -P /tmp"

	display_alert "Install aic8800dc packages, will build kernel module in chroot" "${EXTENSION}" "info"
	declare -ag if_error_find_files_sdcard=("/var/lib/dkms/aic8800*/*/build/*.log")
    use_clean_environment="yes" chroot_sdcard_apt_get_install "/tmp/${aic8800dc_dkms_file_name} /tmp/${aic8800dc_firmware_file_name}"
	use_clean_environment="yes" chroot_sdcard "rm -f /tmp/aic8800*.deb"
	use_clean_environment="yes" chroot_sdcard "mkdir -p /usr/lib/systemd/network/"
	use_clean_environment="yes" chroot_sdcard 'cat <<- EOF > /usr/lib/systemd/network/50-shenmintao-aic8800dc.link
		[Match]
		OriginalName=wlan*
		Driver=usb

		[Link]
		NamePolicy=kernel
	EOF'
}
