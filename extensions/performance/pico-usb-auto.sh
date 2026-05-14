#
# Allow the Pico USB host controller stack to runtime-suspend when idle.
#
function post_repo_customize_image__710_pico_usb_auto() {
	display_alert "Extension: ${EXTENSION}" "Set Pico USB runtime PM to auto" "info"

	mkdir -p "${SDCARD}/etc/udev/rules.d"

	cat > "${SDCARD}/etc/udev/rules.d/99-mpwrd-usb-host-auto.rules" <<-'EOF_UDEV'
	ACTION=="add", SUBSYSTEM=="platform", KERNEL=="ffb00000.usb", TEST=="power/control", ATTR{power/control}="auto"
	ACTION=="add", SUBSYSTEM=="platform", KERNEL=="xhci-hcd.0.auto", TEST=="power/control", ATTR{power/control}="auto"
	EOF_UDEV
}
