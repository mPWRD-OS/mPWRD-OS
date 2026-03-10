#
# Set deterministic Ethernet MAC addresses from board serial on boot.
#
function post_repo_customize_image__700_fixed_eth_mac() {
	display_alert "Extension: ${EXTENSION}" "Install deterministic Ethernet MAC service" "info"

	local script_path="${SDCARD}/usr/local/sbin/mpwrd-fixed-eth-mac"
	local service_path="${SDCARD}/etc/systemd/system/mpwrd-fixed-eth-mac.service"
	local nm_wants_dir="${SDCARD}/etc/systemd/system/NetworkManager.service.wants"
	local networkd_wants_dir="${SDCARD}/etc/systemd/system/systemd-networkd.service.wants"

	mkdir -p \
		"${SDCARD}/usr/local/sbin" \
		"${SDCARD}/etc/systemd/system" \
		"${nm_wants_dir}" \
		"${networkd_wants_dir}"

	cat > "${script_path}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log() {
	if command -v logger >/dev/null 2>&1; then
		logger -t mpwrd-fixed-eth-mac "$*"
	fi
}

read_board_serial() {
	local serial=""

	if [[ -r /proc/device-tree/serial-number ]]; then
		serial="$(tr -d '\000\r\n\t ' < /proc/device-tree/serial-number || true)"
	fi

	if [[ -z "${serial}" && -r /proc/cpuinfo ]]; then
		serial="$(awk -F ': ' '/^Serial/ { print $2 }' /proc/cpuinfo | tail -n 1 | tr -d '\r\n\t ' || true)"
	fi

	printf '%s' "${serial}"
}

hash_hex() {
	local input="$1"

	if command -v sha256sum >/dev/null 2>&1; then
		printf '%s' "${input}" | sha256sum | awk '{ print $1 }'
		return 0
	fi

	if command -v md5sum >/dev/null 2>&1; then
		printf '%s' "${input}" | md5sum | awk '{ print $1 }'
		return 0
	fi

	# POSIX fallback, less ideal than SHA but still deterministic.
	local csum
	csum="$(printf '%s' "${input}" | cksum | awk '{ print $1 }')"
	printf '%08x%08x%08x%08x' "${csum}" "${csum}" "${csum}" "${csum}"
}

mac_from_serial_iface() {
	local serial="$1"
	local iface="$2"
	local hex

	hex="$(hash_hex "${serial}:${iface}")"
	printf '02:%s:%s:%s:%s:%s\n' "${hex:0:2}" "${hex:2:2}" "${hex:4:2}" "${hex:6:2}" "${hex:8:2}"
}

is_target_iface() {
	local iface="$1"

	[[ "${iface}" != "lo" ]] || return 1
	[[ -e "/sys/class/net/${iface}/device" ]] || return 1
	[[ ! -d "/sys/class/net/${iface}/wireless" ]] || return 1
	[[ -r "/sys/class/net/${iface}/type" ]] || return 1
	[[ "$(cat "/sys/class/net/${iface}/type")" == "1" ]] || return 1
}

set_iface_mac() {
	local iface="$1"
	local mac="$2"
	local was_up="no"

	if ip -o link show dev "${iface}" | grep -q "UP"; then
		was_up="yes"
	fi

	if ip link set dev "${iface}" address "${mac}" 2>/dev/null; then
		# Some drivers may drop admin state on address change.
		[[ "${was_up}" == "yes" ]] && ip link set dev "${iface}" up 2>/dev/null || true
		return 0
	fi

	ip link set dev "${iface}" down 2>/dev/null || true
	ip link set dev "${iface}" address "${mac}"
	[[ "${was_up}" == "yes" ]] && ip link set dev "${iface}" up 2>/dev/null || true
}

main() {
	local serial
	serial="$(read_board_serial)"
	if [[ -z "${serial}" ]]; then
		log "Board serial unavailable; skipping MAC setup"
		exit 0
	fi

	local iface_path iface target current
	for iface_path in /sys/class/net/*; do
		[[ -e "${iface_path}" ]] || continue
		iface="${iface_path##*/}"
		is_target_iface "${iface}" || continue

		target="$(mac_from_serial_iface "${serial}" "${iface}")"
		current="$(cat "/sys/class/net/${iface}/address" 2>/dev/null || true)"
		if [[ "${current,,}" == "${target,,}" ]]; then
			continue
		fi

		if set_iface_mac "${iface}" "${target}"; then
			log "Set ${iface} MAC to ${target} from board serial"
		else
			log "Failed setting ${iface} MAC to ${target}"
		fi

		# Keep Ethernet links administratively up; networkd/netplan will handle DHCP.
		ip link set dev "${iface}" up 2>/dev/null || true
	done
}

main "$@"
EOF
	chmod 0755 "${script_path}"

	cat > "${service_path}" <<'EOF'
[Unit]
Description=Set deterministic Ethernet MAC addresses from board serial
Before=network-pre.target
Wants=network-pre.target
After=systemd-udevd.service
ConditionPathExists=/sys/class/net

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/mpwrd-fixed-eth-mac

[Install]
WantedBy=NetworkManager.service
WantedBy=systemd-networkd.service
EOF
	chmod 0644 "${service_path}"

	ln -sf ../mpwrd-fixed-eth-mac.service "${nm_wants_dir}/mpwrd-fixed-eth-mac.service"
	ln -sf ../mpwrd-fixed-eth-mac.service "${networkd_wants_dir}/mpwrd-fixed-eth-mac.service"
}
