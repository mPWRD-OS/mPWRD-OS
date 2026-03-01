#
# Add Avahi service definition for Meshtastic.
#
function post_repo_customize_image__700_avahi_daemon() {
	display_alert "Extension: ${EXTENSION}" "Install Meshtastic Avahi service file" "info"

	local service_path="${SDCARD}/etc/avahi/services/meshtastic.service"

	mkdir -p "${SDCARD}/etc/avahi/services"

	cat > "${service_path}" <<'EOF'
<?xml version="1.0" standalone="no"?><!--*-nxml-*-->
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
    <name>Meshtastic</name>
    <service protocol="ipv4">
        <type>_meshtastic._tcp</type>
        <port>4403</port>
    </service>
</service-group>
EOF
	chmod 0644 "${service_path}"
}
