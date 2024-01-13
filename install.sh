#!/bin/bash

# Initialize variables
ROOT_PARTITION=/dev/nvme0n1p8
LINUX_EFI_PARTITION=/dev/nvme0n1p7
WINDOWS_EFI_PARTITION=/dev/nvme0n1p1
HOSTNAME=nazarix
USERNAME=ainz

# Format partitions
mkfs.ext4 $ROOT_PARTITION
mkfs.vfat $LINUX_EFI_PARTITION

# Mount filesystems
mount $ROOT_PARTITION /mnt
mkdir -p /mnt/boot/arch-efi
mount $LINUX_EFI_PARTITION /mnt/boot/arch-efi
mkdir -p /mnt/boot/win-efi
mount $WINDOWS_EFI_PARTITION /mnt/boot/win-efi

# Install essential packages
pacman-key --init
pacman-key --populate archlinux
pacstrap /mnt base linux linux-firmware amd-ucode nano
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into new system
arch-chroot /mnt /bin/bash << EOF

dd if=/dev/zero of=/swap bs=1K count=2M
chmod 600 /swap
mkswap /swap
swapon /swap
echo "/swap none swap defaults 0 0" >> /etc/fstab

# Time zone and localization
ln -sf /usr/share/zoneinfo/Asia/Manila /etc/localtime
hwclock --systohc
sed -i "/^#en_US.UTF-8 UTF-8/s/^#//" /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network configuration
echo $HOSTNAME > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$HOSTNAME.localdomain\t$HOSTNAME" > /etc/hosts
pacman -S --noconfirm networkmanager wireless_tools
systemctl enable NetworkManager

# Add user account
useradd -mG wheel $USERNAME
pacman -S --noconfirm sudo
sed -i "s/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/" /etc/sudoers
sed -i "s/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/" /etc/sudoers

# Install GRUB bootloader
pacman -S --noconfirm grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot/arch-efi --bootloader-id=GRUB
sed -i "/^#GRUB_DISABLE_OS_PROBER=false/s/^#//" /etc/default/grub
sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/g" /etc/default/grub
sed -i "s/#GRUB_SAVEDEFAULT=.*/GRUB_SAVEDEFAULT=true/g" /etc/default/grub
os-prober
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# Set passwords
echo "Setting root password..."
arch-chroot /mnt /bin/passwd
echo "Setting user password..."
arch-chroot /mnt /bin/passwd $USERNAME