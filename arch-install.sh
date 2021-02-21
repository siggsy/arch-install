#!/bin/bash

# Arguments
ROOT_PARTITION=$1
EFI_PARTITION=$2
HOSTNAME=$3

# Mount partitions
mount $ROOT_PARTITION /mnt
mkdir -p /mnt/boot/efi
mount $EFI_PARTITION /mnt/boot/efi

# Find fastest mirrors
pacman -S --no-confirm reflector rsync
reflector --sort rate --latest 50 --save /etc/pacman.d/mirrorlist

# Install base system
pacstrap /mnt \ 
    base base-devel linux linux-firmware \ # base kernel and dev-tools
    vim neovim \                           # Text editors
    zsh sudo wget git htop \               # Terminal tools
    networkmanager \                       # Networking
    grub efibootmgr                        # Boot

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Arch installation
arch-chroot /mnt

# Local time
ln -sf /usr/share/zoneinfo/Europe/Ljubljana /etc/localtime
hwclock --systohc

# Networking
echo $HOSTNAME >> /etc/hostname
echo "127.0.0.1    localhost\n::1    localhost\n127.0.1.1    $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts
systemctl enable NetworkManager

# Localization
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

mkinitcpio -P

# Bootloader
grub-install $EFI_PARTITION
grub-mkconfig -o /boot/grub/grub.cfg

# Download arch install scripts and dotfiles
git clone https://github.com/siggsy/arch-install.git
git clone https://github.com/siggsy/dotfiles.git

# Change password
passwd

exit
