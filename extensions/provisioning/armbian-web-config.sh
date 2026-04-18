# Armbian Web Config
# https://github.com/Grippy98/armbian-web-config

function post_family_tweaks__install_armbian_web_config() {
	display_alert "Extension: ${EXTENSION}" "Installing armbian-web-config" "info"
	local deb_url="https://github.com/mPWRD-OS/armbian-web-config/releases/download/1.0-1/armbian-web-config_1.0-1_all.deb"
	local deb_file="/tmp/armbian-web-config.deb"

    chroot_sdcard "wget ${deb_url} -O ${deb_file}"
    chroot_sdcard_apt_get_install "${deb_file}"
	rm -f "${deb_file}"
}
