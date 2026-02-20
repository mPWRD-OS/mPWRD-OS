#!/usr/bin/env bash

function pre_umount_final_image__luckfox_perf_terminal_apply() {
	if [[ "${BOARD:-}" != "luckfox-pico-mini" ]]; then
		return 0
	fi

	local rootfs="${MOUNT}"
	mkdir -p "${rootfs}/etc/profile.d"

	cat > "${rootfs}/etc/profile.d/terminal-compat.sh" <<- 'EOF_TERM_COMPAT'
	#!/bin/sh
	# Fallback TERM if client advertises an unknown terminal type.
	if [ -n "${TERM:-}" ] && [ "$TERM" != "dumb" ]; then
	 if command -v infocmp >/dev/null 2>&1; then
	  if ! infocmp "$TERM" >/dev/null 2>&1; then
	   for _fallback in xterm-256color xterm vt100; do
	    if infocmp "$_fallback" >/dev/null 2>&1; then
	     export TERM="$_fallback"
	     break
	    fi
	   done
	  fi
	 fi
	fi
	EOF_TERM_COMPAT

	chmod 0644 "${rootfs}/etc/profile.d/terminal-compat.sh"
	return 0
}
