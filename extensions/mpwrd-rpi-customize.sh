# Enable SPI and I2C

# Run after pre_umount_final_image__write_raspi_config
function pre_umount_final_image__900_customize_raspi_config() {
    cat >> "${MOUNT}"/boot/firmware/config.txt <<- EOF

# mPWRD-OS
dtparam=i2c_arm=on
dtparam=spi=on
EOF
}
