#!/bin/bash

# Source the files
source src/pacman.sh

# Ping a website to check if the network is working
ping -c 1 google.com > /dev/null

# Check if the network is working
if [ $? -ne 0 ]; then
    echo "The network is not working."
    echo "Please check your network connection. Try again later."
    exit 1
fi

# Check if the user has root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run the script as root."
    exit 1
fi

# Check if the package is installed
install "parted"

# Get a list of all the disks
disks=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)

# Print the list of disks with an index
echo "Select a disk to partition:"
echo "$disks" | awk '{print NR,$0}'
echo

# Ask the user to select a disk
read -p "Disk: " disk_index

# Get the disk name from the selected index
disk=$(echo "$disks" | sed -n "${disk_index}p" | awk '{print $1}')

# Print the selected disk
echo "Selected disk: $disk"

# Ask the user to confirm the disk selection
read -p "Are you sure you want to partition $disk? [y/N]: " confirm

# Check if the user confirmed the disk selection
if [ "$confirm" != "y" ]; then
    echo "Exiting..."
    exit 1
fi

# Check if the disk is mounted
if mount | grep -q $disk; then
    # Unmount the disk
    echo "Unmounting $disk..."
    umount $disk
fi

# Format the disk as if the user is running UEFI system
parted --script $disk \
    mklabel gpt \
    mkpart primary fat32 1MiB 261MiB \
    set 1 esp on \
    mkpart primary ext4 261MiB 100%

# Format the EFI partition
mkfs.fat -F32 ${disk}p1

# Format the root partition
mkfs.ext4 ${disk}p2

# Mount the root directory
mount ${disk}p2 /mnt

# Create the boot directory
mkdir /mnt/boot

# Mount the boot directory
mount ${disk}p1 /mnt/boot

# Install the base packages
pacstrap /mnt base linux linux-firmware

# Generate the fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# Change the root directory
arch-chroot /mnt

# Set the timezone
timedatectl set-timezone Europe/London

# Install neovim
install "neovim"

# Set the locale
echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen

# Generate the locale
locale-gen

# Set the locale
echo "LANG=en_GB.UTF-8" > /etc/locale.conf

# Set the keymap
echo "KEYMAP=uk" > /etc/vconsole.conf

# Set the hostname
echo "arch" > /etc/hostname

# Set the hosts file
echo "
127.0.0.1 localhost
::1 localhost
127.0.0.1 arch" > /etc/hosts

# Set the root password
echo "root:password" | chpasswd

# Install the bootloader
install "grub"

# Install the bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# Generate the bootloader configuration
grub-mkconfig -o /boot/grub/grub.cfg

# Exit the chroot environment
exit

# Unmount the disk
umount -l /mnt

# Let the user know the installation is complete
echo "The installation is complete."
echo "Reboot the system and remove the installation media."
echo "Enjoy your new Arch Linux system!"

exit 0
