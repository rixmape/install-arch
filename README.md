# Arch Linux Installation Script on Windows Machine

## Pre-Installation

Follow these steps after booting the machine from the Arch Linux ISO:

### Connect to the internet

1. Check internet connection: `ping www.google.com`
2. Start iwctl environment: `iwctl`
3. List all available commands: `help`
4. List wireless devices: `device list`
5. Scan available wireless networks: `station DEVICE scan`
6. List available wireless networks: `station DEVICE get-networks`
7. Connect to a network: `station DEVICE connect SSID`

### Partition the disk

1. List available block devices: `lsblk`
2. Partition a block device: `cfdisk DEVICE`
3. Select `GPT` as the partition table.
4. Create EFI system partition (ESP) with at least 300 MiB.
5. Use the remaining space of the device for the Linux filesystem (root) partition.

## Installation

### Download the script

1. Download the script: `curl -LJO https://raw.githubusercontent.com/rixmape/install-arch/main/install.sh`

### Run the script

1. Make the script executable: `chmod +x install.sh`
2. Run the script: `./install.sh`

After the script has finished, reboot the machine and remove the installation media.
