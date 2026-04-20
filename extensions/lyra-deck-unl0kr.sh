# Touchscreen LUKS unlock support for encrypted Lyra Zero Deck images.

function extension_prepare_config__add_unl0kr_package() {
	case "${RELEASE}" in
		trixie)
			display_alert "Extension: ${EXTENSION}" "Adding unl0kr package" "info"
			add_packages_to_image unl0kr
			;;
		*)
			display_alert "Extension: ${EXTENSION}" "unl0kr not supported on release: ${RELEASE}" "wrn"
			;;
	esac
}

function lyra_deck_unl0kr__write_config() {
	local config_file="${MOUNT}/etc/unl0kr.conf"
	cat > "${config_file}" <<-'EOF'
	[general]
	animations=false
	backend=fbdev

	[keyboard]
	autohide=false
	layout=us
	popovers=false

	[theme]
	default=breezy-light
	alternate=breezy-dark

	[input]
	keyboard=true
	pointer=false
	touchscreen=true

	[quirks]
	fbdev_force_refresh=true
	EOF
}

function lyra_deck_unl0kr__write_xkb_hook() {
	local hook_file="${MOUNT}/etc/initramfs-tools/hooks/lyra-deck-unl0kr-xkb"

	mkdir -p "$(dirname "${hook_file}")"
	cat > "${hook_file}" <<-'EOF'
	#!/bin/sh
	set -e

	PREREQ=""
	prereqs() { echo "$PREREQ"; }
	case "$1" in
		prereqs)
			prereqs
			exit 0
			;;
	esac

	. /usr/share/initramfs-tools/hook-functions

	if [ -d /usr/share/X11/xkb ]; then
		mkdir -p "${DESTDIR}/usr/share/X11"
		cp -a /usr/share/X11/xkb "${DESTDIR}/usr/share/X11/"
	fi
	EOF

	chmod 0755 "${hook_file}"
}

function lyra_deck_unl0kr__write_dm_control_script() {
	local script_file="${MOUNT}/etc/initramfs-tools/scripts/local-top/lyra-deck-dm-control"

	mkdir -p "$(dirname "${script_file}")"
	cat > "${script_file}" <<-'EOF'
	#!/bin/sh
	set -e

	PREREQ=""
	prereqs() { echo "$PREREQ"; }
	case "$1" in
		prereqs)
			prereqs
			exit 0
			;;
	esac

	modprobe dm_mod 2>/dev/null || modprobe dm-mod 2>/dev/null || true
	mkdir -p /dev/mapper
	[ -c /dev/mapper/control ] || mknod -m 600 /dev/mapper/control c 10 236
	EOF

	chmod 0755 "${script_file}"
}

function lyra_deck_unl0kr__ensure_module() {
	local modules_file="${MOUNT}/etc/initramfs-tools/modules"
	local module_name="$1"

	mkdir -p "$(dirname "${modules_file}")"
	touch "${modules_file}"
	grep -qxF "${module_name}" "${modules_file}" || echo "${module_name}" >> "${modules_file}"
}

function lyra_deck_unl0kr__patch_hook() {
	local hook_file="${MOUNT}/usr/share/initramfs-tools/hooks/unl0kr"

	[[ -f "${hook_file}" ]] || return 0
	grep -q 'armhf)' "${hook_file}" && return 0

	sed -i '
		/^[[:space:]]*amd64)/i\
    armhf)\
        UNL0KR_MODULES="rockchipdrm panel-ilitek-ili9881c panel-osoyoo-dsi panel-simple rpi-panel-v2-regulator pwm_bl backlight goodix_gt9xx goodix_core evdev"\
        ;;\
	' "${hook_file}"
}

function pre_update_initramfs__configure_lyra_deck_unl0kr() {
	local crypttab="${MOUNT}/etc/crypttab"
	local mapper_name="${CRYPTROOT_MAPPER:-armbian-root}"
	local keyscript_option="keyscript=/usr/share/initramfs-tools/scripts/unl0kr-keyscript"
	local initramfs_option="initramfs"
	local crypttab_tmp

	case "${RELEASE}" in
		trixie)
			;;
		*)
			return 0
			;;
	esac

	if [[ ! -f "${crypttab}" ]]; then
		display_alert "Extension: ${EXTENSION}" "crypttab not found, skipping unl0kr wiring" "wrn"
		return 0
	fi

	crypttab_tmp="$(mktemp)"
	awk -v mapper="${mapper_name}" -v keyscript="${keyscript_option}" -v initramfs="${initramfs_option}" '
		function append_option(current, option) {
			if (current == "" || current == "none") {
				return option
			}
			return current "," option
		}

		$1 == mapper {
			if ($4 == "-") {
				$4 = ""
			}
			if ($4 !~ /(^|,)keyscript=/) {
				$4 = append_option($4, keyscript)
			}
			if ($4 !~ /(^|,)initramfs(,|$)/) {
				$4 = append_option($4, initramfs)
			}
		}
		{ print }
	' "${crypttab}" > "${crypttab_tmp}"
	mv "${crypttab_tmp}" "${crypttab}"

	lyra_deck_unl0kr__write_config
	lyra_deck_unl0kr__write_dm_control_script
	lyra_deck_unl0kr__write_xkb_hook
	lyra_deck_unl0kr__patch_hook

	# Include both currently supported deck panel paths and shared touch input
	# so the unlock UI survives display selection changes.
	lyra_deck_unl0kr__ensure_module "panel-ilitek-ili9881c"
	lyra_deck_unl0kr__ensure_module "panel-osoyoo-dsi"
	lyra_deck_unl0kr__ensure_module "panel-simple"
	lyra_deck_unl0kr__ensure_module "rpi-panel-v2-regulator"
	lyra_deck_unl0kr__ensure_module "pwm_bl"
	lyra_deck_unl0kr__ensure_module "backlight"
	lyra_deck_unl0kr__ensure_module "dm_mod"
	lyra_deck_unl0kr__ensure_module "dm_crypt"
	lyra_deck_unl0kr__ensure_module "goodix_gt9xx"
	lyra_deck_unl0kr__ensure_module "goodix_core"
}
