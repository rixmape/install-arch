#!/bin/bash

# Obtain user input
echo "Please enter the Linux root partition:"
read LINUX_ROOT_PARTITION

echo "Please enter the Linux EFI partition:"
read LINUX_EFI_PARTITION

echo "Please enter the Windows EFI partition:"
read WINDOWS_EFI_PARTITION

echo "Please enter the hostname:"
read HOSTNAME

echo "Please enter the username:"
read USERNAME

# Confirm user input
echo "Linux root partition: $LINUX_ROOT_PARTITION"
echo "Linux EFI partition: $LINUX_EFI_PARTITION"
echo "Windows EFI partition: $WINDOWS_EFI_PARTITION"
echo "Hostname: $HOSTNAME"
echo "Username: $USERNAME"

echo "Is this correct? (y/n)"
read CONFIRMATION

if [ "$CONFIRMATION" != "y" ]; then
    echo "Aborting..."
    exit 1
fi

# Format partitions
mkfs.ext4 $LINUX_ROOT_PARTITION
mkfs.vfat $LINUX_EFI_PARTITION

# Mount filesystems
mount $LINUX_ROOT_PARTITION /mnt
mkdir -p /mnt/boot/arch-efi
mount $LINUX_EFI_PARTITION /mnt/boot/arch-efi
mkdir -p /mnt/boot/win-efi
mount $WINDOWS_EFI_PARTITION /mnt/boot/win-efi

# Install essential packages
pacman-key --init
pacman-key --populate archlinux
pacstrap /mnt base linux linux-firmware amd-ucode
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

# Install essential packages
pacman -S --noconfirm nvidia grub efibootmgr os-prober networkmanager wireless_tools sudo base-devel pacman-contrib

# Network configuration
echo $HOSTNAME > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$HOSTNAME.localdomain\t$HOSTNAME" > /etc/hosts
systemctl enable NetworkManager

# Add user account
useradd -mG wheel $USERNAME
sed -i "s/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/" /etc/sudoers
sed -i "s/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/" /etc/sudoers

# Install GRUB bootloader
grub-install --target=x86_64-efi --efi-directory=/boot/arch-efi --bootloader-id=GRUB
sed -i "/^#GRUB_DISABLE_OS_PROBER=false/s/^#//" /etc/default/grub
sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/g" /etc/default/grub
sed -i "s/#GRUB_SAVEDEFAULT=.*/GRUB_SAVEDEFAULT=true/g" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# Set passwords
echo "Setting root password..."
arch-chroot /mnt /bin/passwd
echo "Setting user password..."
arch-chroot /mnt /bin/passwd $USERNAME