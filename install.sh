#!/bin/bash

# Get command line arguments
ROOT_PARTITION=$1
EFI_PARTITION=$2
WINDOWS_EFI_PARTITION=$3
HOSTNAME=$4
USERNAME=$5

# Check if arguments are empty
if [ -z "$ROOT_PARTITION" ] || [ -z "$EFI_PARTITION" ] || [ -z "$WINDOWS_EFI_PARTITION" ] || [ -z "$HOSTNAME" ] || [ -z "$USERNAME" ]; then
    echo "Usage: ./install.sh <root_partition> <efi_partition> <windows_efi_partition> <hostname> <username>"
    exit 1
fi

# Format partitions
mkfs.ext4 $ROOT_PARTITION
mkfs.vfat $EFI_PARTITION

# Mount filesystems
mount $ROOT_PARTITION /mnt
mkdir -p /mnt/boot/arch-efi
mount $EFI_PARTITION /mnt/boot/arch-efi
mkdir -p /mnt/boot/win-efi
mount $WINDOWS_EFI_PARTITION /mnt/boot/win-efi

# Install essential packages
pacstrap /mnt base linux linux-firmware amd-ucode nano
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into new system
arch-chroot /mnt

# Swap file
dd if=/dev/zero of=/swap bs=1K count=2M
chmod 600 /swap
mkswap /swap
swapon /swap
echo '/swap none swap defaults 0 0' >> /etc/fstab

# Time zone and localization
ln -sf /usr/share/zoneinfo/Asia/Manila /etc/localtime
hwclock --systohc
sed -i '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# Network configuration
echo $HOSTNAME > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$HOSTNAME.localdomain\t$HOSTNAME" > /etc/hosts
pacman -S --no-confirm networkmanager wireless_tools
systemctl enable NetworkManager

# Add user account
echo "Setting root password"
passwd
useradd -mG wheel $USERNAME
echo "Setting user password for $USERNAME"
passwd $USERNAME
pacman -S --no-confirm sudo
sed -i '/^#%wheel ALL = (ALL:ALL) ALL/s/^#//' /etc/sudoers

# Install GRUB bootloader
pacman -S --no-confirm grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot/arch-efi --bootloader-id=GRUB
sed -i '/^#GRUB_DISABLE_OS_PROBER=false/s/^#//' /etc/default/grub
echo -e "GRUB_DEFAULT=saved\nGRUB_SAVEDEFAULT=true" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Finish system configuration
echo "Unmounting file systems and shutting down..."
umount -R /mnt