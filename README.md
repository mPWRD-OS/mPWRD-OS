# mPWRD-OS
[Armbian](https://armbian.com/) + [Meshtastic](https://meshtastic.org/) == **mPWRD-OS**

## Features
- 🐧 Debian 13 `trixie` based.
- ❤️ Built with [Armbian](https://armbian.com/) *userpatches* framework.
- 🛜 [meshtasticd](https://meshtastic.org/docs/hardware/devices/linux-native-hardware/) pre-installed and working out of the box.
- 🛠️ [mpwrd-menu](https://github.com/mPWRD-OS/mpwrd-menu) simple OS management utility.

## Board Support

| Chipset  | Board                    | Status    |
| -------- | ------------------------ | --------- |
| RK3506G  | 🛜 EByte ECB41-PGE       | WIP       |
| RK3506G  | 🦊 Luckfox Lyra Plus     | Supported |
| RK3506B  | 🦊 Luckfox Lyra Ultra W  | Supported |
| RK3506B  | 🦊 Luckfox Lyra Zero W   | WIP       |
| RK3506J  | 🐈 ForLinx OK3506-S12    | WIP       |
| RV1106G  | 🦊 Luckfox Pico Max      | WIP       |
| RV1103G  | 🦊 Luckfox Pico Mini     | Supported |
| RV1103B  | 🧅 OnionIOT Omega4       | Todo      |
| BCM2711  | 🍓 Raspberry Pi (64-bit) | Supported |
| UEFI     | 🖥️ Generic x86_64 UEFI   | Dev       |

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
