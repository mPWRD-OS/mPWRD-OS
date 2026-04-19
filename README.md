# mPWRD-OS
[Armbian](https://armbian.com/) + [Meshtastic](https://meshtastic.org/) == **mPWRD-OS**

## Features
- 🐧 Debian 13 `trixie` based.
- ❤️ Built with [Armbian](https://armbian.com/) *userpatches* framework.
- Ⓜ️ [meshtasticd](https://meshtastic.org/docs/hardware/devices/linux-native-hardware/) pre-installed and working out of the box.
- 🐍 [meshtastic](https://meshtastic.org/docs/software/python/cli/) CLI pre-installed.
- 📡 [contact](https://github.com/pdxlocations/contact) Meshtastic TUI pre-installed.
- 🧙 [mpwrd-menu](https://github.com/mPWRD-OS/mpwrd-menu) simple OS / Meshtastic management utility.
- 🔵 [BLE WiFi provisioning](https://github.com/mPWRD-OS/mPWRD-OS/wiki/Provisioning#ble-provisioning) via the Meshtastic Apps / Flasher.
  - Powered by 🏠 [Nymea-NetworkManager](https://github.com/nymea/nymea-networkmanager).
  - Supported on Raspberry Pi.
- 🛜 [Web provisioning](https://github.com/mPWRD-OS/mPWRD-OS/wiki/Provisioning#web-provisioning) via temporary `armbiansetup` hotspot.
  - Powered by 🌐 [armbian-web-config](https://github.com/Grippy98/armbian-web-config).
  - Supported on Luckfox Lyra Zero W and Luckfox Lyra Ultra W with more to come.

## Board Support

> [!TIP]
> Some boards require preparation before mPWRD-OS can be used, see the [Board Support](https://github.com/mPWRD-OS/mPWRD-OS/wiki/Board-Support) wiki page.

| Chipset  | Board                          | Status    | `meshtasticd` status |
| -------- | ------------------------------ | --------- | -------------------- |
| BCM2711  | 🍓 [Raspberry Pi (64-bit)][b1] | Supported | ✅ `beta`            |
| RK3506G  | 🛜 [EByte ECB41-PGE][b2]       | Supported | 🧪 `alpha`           |
| RK3506G  | 🦊 [Luckfox Lyra Plus][b3]     | Supported | 🧪 `alpha`           |
| RK3506B  | 🦊 [Luckfox Lyra Ultra W][b4]  | Supported | 🧪 `alpha`           |
| RK3506B  | 🦊 [Luckfox Lyra Zero W][b5]   | Supported | 🧪 `alpha`           |
| RK3506J  | 🐈 [ForLinx OK3506-S12][b6]    | Supported | 🧪 `alpha`           |
| RV1106G  | 🦊 [Luckfox Pico Max][b7]      | Supported | 🚧 `daily`           |
| RV1103G  | 🦊🤏 [Luckfox Pico Mini][b8]   | Supported | ✅ `beta`            |
| RV1103B  | 🧅 [OnionIOT Omega4][b9]       | Todo      |                      |
| UEFI     | 🖥️ [Generic x86_64 UEFI][b10]  | Dev       | ✅ `beta`            |

[b1]: https://github.com/mPWRD-OS/mPWRD-OS/wiki/Board-Support#raspberry-pi-64-bit
[b2]: https://github.com/mPWRD-OS/mPWRD-OS/wiki/Board-Support#ebyte-ecb41-pge
[b3]: https://github.com/mPWRD-OS/mPWRD-OS/wiki/Board-Support#luckfox-lyra-plus
[b4]: https://github.com/mPWRD-OS/mPWRD-OS/wiki/Board-Support#luckfox-lyra-ultra-w
[b5]: https://github.com/mPWRD-OS/mPWRD-OS/wiki/Board-Support#luckfox-lyra-zero-w
[b6]: https://github.com/mPWRD-OS/mPWRD-OS/wiki/Board-Support#forlinx-ok3506-s12
[b7]: https://github.com/mPWRD-OS/mPWRD-OS/wiki/Board-Support#luckfox-pico-max
[b8]: https://github.com/mPWRD-OS/mPWRD-OS/wiki/Board-Support#luckfox-pico-mini
[b9]: https://github.com/mPWRD-OS/mPWRD-OS/wiki/Board-Support#onioniot-omega4
[b10]: https://github.com/mPWRD-OS/mPWRD-OS/wiki/Board-Support#generic-x86_64-uefi

## Default Credentials

| Username | Password |
| -------: | :------- |
| `root`   | `1234`   |

## Using mPWRD-OS
See Also: [mPWRD-OS Provisioning](https://github.com/mPWRD-OS/mPWRD-OS/wiki/Provisioning)

1. Flash the latest image from the [Releases](https://github.com/mPWRD-OS/mPWRD-OS/releases) page using [balenaEtcher](https://etcher.balena.io/) or a similar tool.
   - For boards with eMMC: [Flash with `rkdevtool`](https://github.com/mPWRD-OS/mPWRD-OS/wiki/Rockchip-Flashing).
2. SSH into the device (or connect with Serial), login with default credentials. You will be prompted to change this upon first login.
3. Run `mpwrd-menu` to setup Meshtastic, change settings, and more!

## Using this repo

1. Checkout `armbian/build` and enter the dir
```sh
git clone https://github.com/armbian/build.git
cd build
```

2. Checkout this repo as "userpatches"
```sh
git clone https://github.com/mPWRD-OS/mPWRD-OS userpatches
```

3. Compile!
```sh
./compile.sh luckfox-pico-mini
```
This example will build the configuration at `config-luckfox-pico-mini.conf`
