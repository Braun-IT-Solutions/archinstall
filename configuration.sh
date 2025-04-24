#!/bin/bash

# Catches errors and stops the script early
set -eo pipefail

SCRIPT_PATH=$(dirname "$0")
cd "$SCRIPT_PATH"
source ./util.sh

# Base packages to install
PACKAGES="base base-devel linux linux-firmware git nano cryptsetup amd-ucode sbctl sudo htop btop nvtop dhcpcd"
# Hooks for mkinitcpio
HOOKS="base systemd autodetect modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck"

# Usage message for incorrect parameters
function usage() {
    OUTPUT="╔═══════════════════════════════════╗
║ Error with parameters, exiting... ║
║ \$1 username                      ║
║ \$2 hostname                      ║
║ \$3 password                      ║
╚═══════════════════════════════════╝"
    printColor "$OUTPUT" RED
    exit 1
}

# Check required parameters - improved logic
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    usage
fi

LOGIN_NAME="$1"
HOSTNAME="$2"
DEFAULT_PASSWORD="$3"

# Installs basic packages and system files
function install_linux() {
    printColor "Finding fastest mirrors..." GREEN
    # Retrieves and filters the latest pacman mirror list
    reflector --country DE --age 24 --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist

    printColor "Installing basic linux..." GREEN
    # Comes preinstalled with arch, designed to create new system installations
    # -K initializes a new pacman keyring
    pacstrap -K /mnt $PACKAGES
}

# Generates locales, german keyboard and hostname
function configure_basics() {
    printColor "Settings timezone..." GREEN
    # Sets Timezone Berlin
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

    printColor "Setting hardware clock..." GREEN
    # Sets the hardwareclock to current system time
    arch-chroot /mnt hwclock --systohc

    printColor "Setting locales..." GREEN
    # Setting german locales and EN-USA as fallback
    sed -i -e "/^#"de_DE.UTF-8"/s/^#//" /mnt/etc/locale.gen
    sed -i -e "/^#"en_US.UTF-8"/s/^#//" /mnt/etc/locale.gen

    printColor "Setting keymap..." GREEN
    # Sets german keyboard
    echo "KEYMAP=de-latin1" >/mnt/etc/vconsole.conf

    printColor "Setting hostname..." GREEN
    # Sets hostname
    echo "$HOSTNAME" >/mnt/etc/hostname

    printColor "Generating locales..." GREEN
    # Generates locales
    arch-chroot /mnt locale-gen
}

# Setup for user with "$LOGIN_NAME"
function create_user() {
    printColor "Creating user..." GREEN
    arch-chroot /mnt useradd -G wheel -m "$LOGIN_NAME"
    echo $DEFAULT_PASSWORD | arch-chroot /mnt passwd $LOGIN_NAME --stdin
}

# Configures sudo to not need password
function configure_sudo() {
    printColor "Configuring sudo..." GREEN
    sed -i -e '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' /mnt/etc/sudoers
}

# Enables systemd & dhcpcd services
function enable_services() {
    printColor "Enabling systemd services..." GREEN
    systemctl --root /mnt enable systemd-resolved systemd-timesyncd dhcpcd
}

# Sets unified kernel images and generates them
function setup_uki() {
    printColor "Setting up UKI..." GREEN

    # Sets kernel parameters
    # "rw: Mount root device read-write on boot"
    echo "rw" >/mnt/etc/kernel/cmdline
    mkdir -p /mnt/efi/EFI/Linux

    printColor "Setting mkinitcpio hooks..." GREEN
    # Setting our hooks for mkinitcpio
    sed -i -e "s/^HOOKS=.*/HOOKS=($HOOKS)/g" /mnt/etc/mkinitcpio.conf

    printColor "Enabling UKI..." GREEN
    # Enabling our UKIs
    sed -i -e "s/^default_config=/#default_config=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^default_image=/#default_image=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#default_uki=/default_uki=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#default_options=/default_options=/g" /mnt/etc/mkinitcpio.d/linux.preset

    sed -i -e "s/^fallback_config=/#fallback_config=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^fallback_image=/#fallback_image=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#fallback_uki=/fallback_uki=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#fallback_options=/fallback_options=/g" /mnt/etc/mkinitcpio.d/linux.preset

    printColor "Generating UKI..." GREEN
    # Generates initramfs image based on kernel packages
    # "-P: re-generates all initramfs images"
    arch-chroot /mnt mkinitcpio -P

    printColor "Installing bootloader..." GREEN
    # Install EFI bootloader
    # "--esp-path=: path to our efi partition"
    arch-chroot /mnt bootctl install --esp-path=/efi

    enable_services

    sync
}

function setup_user_env() {
    printColor "Setting up user environment..." GREEN

    # Backup the original bashrc
    cp /mnt/home/$LOGIN_NAME/.bashrc /mnt/home/$LOGIN_NAME/.bashrcBACKUP
    rm -f /mnt/home/$LOGIN_NAME/.bashrc

    # Copy necessary files
    cat "secure-boot.sh" > "/mnt/home/$LOGIN_NAME/post-arch-install.sh"
    echo "./post-arch-install.sh" > "/mnt/home/$LOGIN_NAME/.bashrc"

    arch-chroot /mnt chown "$LOGIN_NAME:$LOGIN_NAME" "/home/$LOGIN_NAME/post-arch-install.sh"
    arch-chroot /mnt chmod +x "/home/$LOGIN_NAME/post-arch-install.sh"

    cat util.sh >/mnt/home/$LOGIN_NAME/util.sh
    echo "1" >/mnt/home/$LOGIN_NAME/tmp.txt

    # Handle LUKS key file securely
    cp luks-temp.key /mnt/home/$LOGIN_NAME/luks-temp.key
    chmod 400 /mnt/home/$LOGIN_NAME/luks-temp.key

    # Set proper ownership
    arch-chroot /mnt chown -R $LOGIN_NAME:$LOGIN_NAME /home/$LOGIN_NAME
}

install_linux
configure_basics
create_user
configure_sudo
setup_uki
setup_user_env
