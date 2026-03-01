#
# Install mpwrd-menu into the final image.
#
function post_repo_customize_image__700_mpwrd_menu() {
	display_alert "Extension: ${EXTENSION}" "Install mpwrd-menu" "info"

	local repo_owner="${MPWRD_MENU_REPO_OWNER:-mPWRD-OS}"
	local repo_name="${MPWRD_MENU_REPO_NAME:-mpwrd-menu}"
	local repo_ref="${MPWRD_MENU_REF:-main}"
	local base_url="https://raw.githubusercontent.com/${repo_owner}/${repo_name}/${repo_ref}"
	local share_dir="${SDCARD}/usr/local/share/mpwrd-menu"
	local bin_dir="${SDCARD}/usr/local/bin"
	local etc_dir="${SDCARD}/etc/mpwrd-menu"
	local tmp_dir

	tmp_dir="$(mktemp -d)"

	download_mpwrd_menu_file "${base_url}/mpwrd-menu.sh" "${tmp_dir}/mpwrd-menu.sh"
	download_mpwrd_menu_file "${base_url}/mesh-apps.conf.example" "${tmp_dir}/mesh-apps.conf.example"
	download_mpwrd_menu_file "${base_url}/mesh-services.conf.example" "${tmp_dir}/mesh-services.conf.example"

	mkdir -p "${share_dir}" "${bin_dir}" "${etc_dir}"

	install -m 0755 "${tmp_dir}/mpwrd-menu.sh" "${share_dir}/mpwrd-menu.sh"
	install -m 0644 "${tmp_dir}/mesh-apps.conf.example" "${share_dir}/mesh-apps.conf.example"
	install -m 0644 "${tmp_dir}/mesh-services.conf.example" "${share_dir}/mesh-services.conf.example"

	if [[ ! -e "${etc_dir}/mesh-apps.conf" ]]; then
		install -m 0644 "${tmp_dir}/mesh-apps.conf.example" "${etc_dir}/mesh-apps.conf"
	fi

	if [[ ! -e "${etc_dir}/mesh-services.conf" ]]; then
		install -m 0644 "${tmp_dir}/mesh-services.conf.example" "${etc_dir}/mesh-services.conf"
	fi

	cat > "${bin_dir}/mpwrd-menu" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

export APP_REGISTRY=/etc/mpwrd-menu/mesh-apps.conf
export SERVICE_REGISTRY=/etc/mpwrd-menu/mesh-services.conf

exec /usr/local/share/mpwrd-menu/mpwrd-menu.sh "$@"
EOF
	chmod 0755 "${bin_dir}/mpwrd-menu"

	rm -rf "${tmp_dir}"
}

download_mpwrd_menu_file() {
	local url="$1"
	local destination="$2"

	if command -v curl >/dev/null 2>&1; then
		curl -fsSL "${url}" -o "${destination}"
		return 0
	fi

	if command -v wget >/dev/null 2>&1; then
		wget -qO "${destination}" "${url}"
		return 0
	fi

	display_alert "Extension: ${EXTENSION}" "curl or wget is required to install mpwrd-menu" "err"
	return 1
}
