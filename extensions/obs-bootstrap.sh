# shellcheck shell=bash
#
# Shared OBS bootstrap helpers for Armbian extension hooks.
#
function __obs_bootstrap_add_signed_repo() {
	local repo_url="$1"
	local key_url="$2"
	local list_name="$3"
	local keyring_name="$4"
	local sources_dir="${SDCARD}/etc/apt/sources.list.d"
	local keyring_dir="${SDCARD}/etc/apt/keyrings"
	local list_host_path="${sources_dir}/${list_name}"
	local keyring_host_path="${keyring_dir}/${keyring_name}"
	local keyring_guest_path="/etc/apt/keyrings/${keyring_name}"
	local tmp_key
	local rc=0

	tmp_key="$(mktemp)"

	run_host_command_logged install -d -m 0755 "${sources_dir}" "${keyring_dir}" || rc=$?
	if [[ ${rc} -eq 0 ]]; then
		run_host_command_logged curl -fsSL "${key_url}" -o "${tmp_key}" || rc=$?
	fi
	if [[ ${rc} -eq 0 ]]; then
		run_host_command_logged gpg --dearmor --batch --yes -o "${keyring_host_path}" "${tmp_key}" || rc=$?
	fi
	if [[ ${rc} -eq 0 ]]; then
		run_host_command_logged chmod 0644 "${keyring_host_path}" || rc=$?
	fi
	if [[ ${rc} -eq 0 ]]; then
		printf 'deb [signed-by=%s] %s /\n' "${keyring_guest_path}" "${repo_url}" > "${list_host_path}" || rc=$?
	fi
	if [[ ${rc} -eq 0 ]]; then
		run_host_command_logged chmod 0644 "${list_host_path}" || rc=$?
	fi

	rm -f "${tmp_key}"
	return "${rc}"
}
