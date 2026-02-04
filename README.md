# mPWRD-userpatches
Armbian + Meshtastic == mPWRD OS

## Board Support

| Chipset  | Board                    | Status |
| -------- | ------------------------ | ------ |
| RK3506G  | 🛜 EByte ECB41-PGE1N2-N  | Todo   |
| RK3506G  | 🦊 Luckfox Lyra Plus     | WIP    |
| RK3506B  | 🦊 Luckfox Lyra Ultra W  | WIP    |
| RK3506B  | 🦊 Luckfox Lyra Zero W   | WIP    |
| RK3506J  | 🐈 ForLinx OK3506-S12    | Todo   |
| RV1106G  | 🦊 Luckfox Pico Max      | WIP    |
| RV1103   | 🦊 Luckfox Pico Mini     | WIP    |
| BCM2711  | 🍓 Raspberry Pi (64-bit) | WIP    |
| UEFI     | 🖥️ Generic x86_64 UEFI   | Dev    |

## Using this repo

1. Checkout `armbian/build` and enter the dir
```sh
git clone https://github.com/armbian/build.git
cd build
```

2. Checkout this repo as "userpatches"
```sh
git clone https://github.com/mPWRD-OS/mPWRD-userpatches userpatches
```

3. Compile!
```sh
./compile.sh build luckfox-pico-mini
```
This example will build the configuration at `config-luckfox-pico-mini.conf`
