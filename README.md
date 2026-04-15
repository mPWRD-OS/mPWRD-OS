# mPWRD-OS
[Armbian](https://armbian.com/) + [Meshtastic](https://meshtastic.org/) == **mPWRD-OS**

## Features
- 🐧 Debian 13 `trixie` based.
- ❤️ Built with [Armbian](https://armbian.com/) *userpatches* framework.
- 🛜 [meshtasticd](https://meshtastic.org/docs/hardware/devices/linux-native-hardware/) pre-installed and working out of the box.
- 🐍 [meshtastic](https://meshtastic.org/docs/software/python/cli/) CLI pre-installed.
- 📡 [contact](https://github.com/pdxlocations/contact) Meshtastic TUI pre-installed.
- 🧙 [mpwrd-menu](https://github.com/mPWRD-OS/mpwrd-menu) simple OS / Meshtastic management utility.
- 🔵 BLE WiFi provisioning via the Meshtastic Apps / Flasher.
  - Powered by 🏠 [Nymea-NetworkManager](https://github.com/nymea/nymea-networkmanager)
  - Currently only supported on Raspberry Pi.

## Board Support

See: [Board Support](https://github.com/mPWRD-OS/mPWRD-OS/wiki/Board-Support) wiki page.

| Chipset  | Board                    | Status    | `meshtasticd` status |
| -------- | ------------------------ | --------- | -------------------- |
| BCM2711  | 🍓 Raspberry Pi (64-bit) | Supported | ✅ `beta`            |
| RK3506G  | 🛜 EByte ECB41-PGE       | Supported | 🧪 `alpha`           |
| RK3506G  | 🦊 Luckfox Lyra Plus     | Supported | 🧪 `alpha`           |
| RK3506B  | 🦊 Luckfox Lyra Ultra W  | Supported | 🧪 `alpha`           |
| RK3506B  | 🦊 Luckfox Lyra Zero W   | Supported | 🧪 `alpha`           |
| RK3506J  | 🐈 ForLinx OK3506-S12    | Supported | 🧪 `alpha`           |
| RV1106G  | 🦊 Luckfox Pico Max      | WIP       | 🚧                   |
| RV1103G  | 🦊🤏 Luckfox Pico Mini   | Supported | ✅ `beta`            |
| RV1103B  | 🧅 OnionIOT Omega4       | Todo      |                      |
| UEFI     | 🖥️ Generic x86_64 UEFI   | Dev       | ✅ `beta`            |

## Default Credentials

| Username | Password |
| -------: | :------- |
| `root`   | `1234`   |

## Using mPWRD-OS

1. Flash the latest image from the [Releases](https://github.com/mPWRD-OS/mPWRD-OS/releases) page using [balenaEtcher](https://etcher.balena.io/) or a similar tool.
   - For boards with eMMC: Flash with `rkdevtool`. (Guide coming soon).
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
./compile.sh build luckfox-pico-mini
```
This example will build the configuration at `config-luckfox-pico-mini.conf`
