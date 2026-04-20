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

	if [ -r /root/.lyra-cryptroot-passphrase ]; then
		mkdir -p "${DESTDIR}/root"
		cp -a /root/.lyra-cryptroot-passphrase "${DESTDIR}/root/"
	fi
	EOF

	chmod 0755 "${hook_file}"
}

function lyra_deck_unl0kr__write_keyscript() {
	local keyscript_file="${MOUNT}/usr/share/initramfs-tools/scripts/lyra-deck-unl0kr-keyscript"

	mkdir -p "$(dirname "${keyscript_file}")"
	cat > "${keyscript_file}" <<-'EOF'
	#!/bin/sh

	if [ -z "${CRYPTTAB_SOURCE}" ] || [ -z "${CRYPTTAB_NAME}" ]; then
		echo "This is a crypttab keyscript script, don't run directly." 1>&2
		exit 1
	fi

	if [ -r /root/.lyra-cryptroot-passphrase ]; then
		cat /root/.lyra-cryptroot-passphrase
		exit 0
	fi

	plymouth hide-splash 2>/dev/null

	ttymode=$(stty -g)
	stty -echo -icanon min 0 time 0

	unl0kr

	stty "$ttymode"

	plymouth show-splash 2>/dev/null
	EOF

	chmod 0755 "${keyscript_file}"
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

function lyra_deck_unl0kr__write_firstlogin_cryptroot_helper() {
	local helper_file="${SDCARD}/usr/lib/armbian/armbian-firstlogin-cryptroot"

	mkdir -p "$(dirname "${helper_file}")"
	cat > "${helper_file}" <<-'EOF'
	#!/bin/bash

	lyra_deck_firstlogin_cryptroot_backing_device() {
		local root_source mapper_name

		root_source="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
		[[ "${root_source}" == /dev/mapper/* ]] || return 1

		mapper_name="${root_source#/dev/mapper/}"
		cryptsetup status "${mapper_name}" 2>/dev/null | awk '$1 == "device:" { print $2; exit }'
	}

	lyra_deck_firstlogin_cryptroot_prompt() {
		local marker="/root/.lyra-cryptroot-passphrase-set"
		local seed_file="/root/.lyra-cryptroot-passphrase"
		local backing_device current_passphrase new_passphrase repeated_passphrase
		local current_file new_file remaining_tries current_mode

		[[ -e "${marker}" ]] && return 0
		command -v cryptsetup >/dev/null 2>&1 || return 0

		backing_device="$(lyra_deck_firstlogin_cryptroot_backing_device)"
		[[ -n "${backing_device}" ]] || return 0

		current_mode="prompt"
		if [[ -r "${seed_file}" ]]; then
			current_passphrase="$(cat "${seed_file}")"
			[[ -n "${current_passphrase}" ]] && current_mode="seed"
		fi

		echo ""
		echo "Set the disk unlock passphrase."

		remaining_tries=3
		while [[ "${remaining_tries}" -gt 0 ]]; do
			if [[ "${current_mode}" == "seed" ]]; then
				current_passphrase="$(cat "${seed_file}")"
			else
				read_password "Current disk unlock"
				echo ""
				current_passphrase="${password}"
			fi

			read_password "Create disk unlock"
			echo ""
			new_passphrase="${password}"

			read_password "Repeat disk unlock"
			echo ""
			repeated_passphrase="${password}"

			if [[ -z "${current_passphrase}" || -z "${new_passphrase}" ]]; then
				remaining_tries=$((remaining_tries - 1))
				echo -e "Rejected - \e[0;31mpassphrase cannot be empty.\x1B[0m Try again [${remaining_tries}]."
				continue
			fi

			if [[ "${new_passphrase}" != "${repeated_passphrase}" ]]; then
				remaining_tries=$((remaining_tries - 1))
				echo -e "Rejected - \e[0;31mpassphrases do not match.\x1B[0m Try again [${remaining_tries}]."
				continue
			fi

			current_file="$(mktemp)"
			new_file="$(mktemp)"
			chmod 600 "${current_file}" "${new_file}"
			printf '%s' "${current_passphrase}" > "${current_file}"
			printf '%s' "${new_passphrase}" > "${new_file}"

			if cryptsetup luksChangeKey "${backing_device}" "${new_file}" --batch-mode --key-file "${current_file}" >/dev/null 2>&1; then
				rm -f "${current_file}" "${new_file}"
				rm -f "${seed_file}"
				: > "${marker}"
				chmod 600 "${marker}"
				update-initramfs -u >/dev/null 2>&1 || true
				echo -e "\nDisk unlock passphrase updated.\n"
				return 0
			fi

			rm -f "${current_file}" "${new_file}"
			[[ "${current_mode}" == "seed" ]] && current_mode="prompt"
			remaining_tries=$((remaining_tries - 1))
			echo -e "Rejected - \e[0;31mcurrent disk unlock passphrase is incorrect or the change failed.\x1B[0m Try again [${remaining_tries}]."
		done

		echo -e "\n\x1B[91mError\x1B[0m: disk unlock passphrase was not updated."
		return 1
	}
	EOF

	chmod 0755 "${helper_file}"
}

function lyra_deck_unl0kr__write_firstlogin_cryptroot_seed() {
	local seed_file="${SDCARD}/root/.lyra-cryptroot-passphrase"

	[[ -n "${CRYPTROOT_PASSPHRASE:-}" ]] || return 0

	mkdir -p "$(dirname "${seed_file}")"
	printf '%s' "${CRYPTROOT_PASSPHRASE}" > "${seed_file}"
	chmod 0600 "${seed_file}"
}

function lyra_deck_unl0kr__patch_firstlogin() {
	local firstlogin_file="${SDCARD}/usr/lib/armbian/armbian-firstlogin"

	[[ -f "${firstlogin_file}" ]] || return 0
	grep -q 'lyra_deck_firstlogin_cryptroot_prompt' "${firstlogin_file}" && return 0

	sed -i '/\[\[ -z "\$PRESET_ROOT_PASSWORD" \]\] && echo "" # empty line/i \
	if [[ -r /usr/lib/armbian/armbian-firstlogin-cryptroot ]]; then\
		. /usr/lib/armbian/armbian-firstlogin-cryptroot\
		lyra_deck_firstlogin_cryptroot_prompt || exit 1\
	fi\
' "${firstlogin_file}"
}

function post_family_tweaks__configure_lyra_deck_firstlogin_cryptroot() {
	case "${RELEASE}" in
		trixie)
			;;
		*)
			return 0
			;;
	esac

	[[ "${CRYPTROOT_ENABLE}" == "yes" ]] || return 0

	lyra_deck_unl0kr__write_firstlogin_cryptroot_helper
	lyra_deck_unl0kr__write_firstlogin_cryptroot_seed
	lyra_deck_unl0kr__patch_firstlogin
}

function pre_update_initramfs__configure_lyra_deck_unl0kr() {
	local crypttab="${MOUNT}/etc/crypttab"
	local mapper_name="${CRYPTROOT_MAPPER:-armbian-root}"
	local keyscript_option="keyscript=/usr/share/initramfs-tools/scripts/lyra-deck-unl0kr-keyscript"
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
	lyra_deck_unl0kr__write_keyscript
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
