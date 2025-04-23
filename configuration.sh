#!/bin/bash

DEFAULT_PASSWORD="root"

#Checks for both parameters
#1: Login-name
#2: Hostname
check_parameters() {
    if ! [ -n "$1" ] && [ " " != "$1" ] && ! [ -n "$2" ] && [ " " != "$2" ] 2>/dev/null; then
        OUTPUT="\
        ╔═══════════════════════════════════╗\n\
        ║ Error with parameters, exiting... ║\n\
        ╚═══════════════════════════════════╝\n"
        printColor "$OUTPUT" RED
        sleep 5
        exit 1
    fi
}

#Installs basic packages and system files
function install_linux() {
    printColor "Finding fastest mirrors..." GREEN
    #Retrieves and filters the latest pacman mirror list
    reflector --country DE --age 24 --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist

    printColor "Installing basic linux..." GREEN
    #Packages to install
    PACKAGES="base base-devel linux linux-firmware git nano cryptsetup amd-ucode sbctl sudo htop btop nvtop dhcpcd"
    #Comes preinstalled with arch, designed to create new system installations
    #-K initializes a new pacman keyring
    pacstrap -K /mnt $PACKAGES
}

# $1 hostname
#Generates locales, german keyboard and hostname
function configure_basics() {

    printColor "Settings timezone..." GREEN
    #Sets Timezone Berlin
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

    printColor "Setting hardware clock..." GREEN
    #Sets the hardwareclock to current system time
    arch-chroot /mnt hwclock --systohc

    printColor "Setting locales..." GREEN

    #Setting german locales and EN-USA as fallback
    sed -i -e "/^#"de_DE.UTF-8"/s/^#//" /mnt/etc/locale.gen
    sed -i -e "/^#"en_US.UTF-8"/s/^#//" /mnt/etc/locale.gen

    printColor "Setting keymap..." GREEN
    #Sets german keyboard
    echo "KEYMAP=de-latin1" >/mnt/etc/vconsole.conf

    printColor "Setting hostname..." GREEN
    #sets hostname
    echo $1 >/mnt/etc/hostname

    printColor "Generating locales..." GREEN
    #Generates locales
    arch-chroot /mnt locale-gen
}

# $1 username
#Setup for user with "$LOGIN_NAME"
function create_user() {
    printColor "Creating user..." GREEN
    arch-chroot /mnt useradd -G wheel -m $1
    echo $DEFAULT_PASSWORD | arch-chroot /mnt passwd $1 --stdin
}

#Configures sudo to not need password
function configure_sudo() {
    printColor "Configuring sudo..." GREEN
    sed -i -e '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' /mnt/etc/sudoers
}

#Enables systemd & dhcpcd services
function enable_services() {
    printColor "Enabling systemd services..." GREEN
    systemctl --root /mnt enable systemd-resolved systemd-timesyncd dhcpcd
}

# $1 username
#Sets unified kernel images and generates them
function setup_uki() {
    printColor "Setting up UKI..." GREEN

    #Sets kernel parameters
    #"rw: Mount root device read-write on boot"
    echo "rw" >/mnt/etc/kernel/cmdline
    mkdir -p /mnt/efi/EFI/Linux

    printColor "Setting mkinitcpio hooks..." GREEN
    HOOKS="base systemd autodetect modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck"
    #Setting our hooks for mkinitcpio
    sed -i -e "s/^HOOKS=.*/HOOKS=($HOOKS)/g" /mnt/etc/mkinitcpio.conf

    printColor "Enabling UKI..." GREEN
    #Enabling our UKIs
    sed -i -e "s/^default_config=/#default_config=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^default_image=/#default_image=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#default_uki=/default_uki=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#default_options=/default_options=/g" /mnt/etc/mkinitcpio.d/linux.preset

    sed -i -e "s/^fallback_config=/#fallback_config=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^fallback_image=/#fallback_image=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#fallback_uki=/fallback_uki=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#fallback_options=/fallback_options=/g" /mnt/etc/mkinitcpio.d/linux.preset

    printColor "Generating UKI..." GREEN
    #Generates initramfs image based on kernel packages
    #"-P: re-generates all initramfs images"
    arch-chroot /mnt mkinitcpio -P

    printColor "Installing bootloader..." GREEN
    #Install EFI bootloader
    #"--esp-path=: path to our efi partition"
    arch-chroot /mnt bootctl install --esp-path=/efi

    enable_services

    sync

    printColor "Setting up temp files..." GREEN

    #$1 = $LOGIN_NAME
    cp /mnt/home/$1/.bashrc /mnt/home/$1/.bashrcBACKUP
    rm -rf /mnt/home/$1/.bashrc

    cat secure-boot.sh >/mnt/home/$1/.bashrc
    cat util.sh >/mnt/home/$1/util.sh
    echo "1" >/mnt/home/$1/tmp.txt

    cp luks-temp.key /mnt/home/$1/luks-temp.key
    chmod 400 /mnt/home/$1/luks-temp.key
}

# $1 = LOGIN_NAME
# $2 = HOST_NAME
# $3 = TEMPORARY PASSWORD
function doReboot() {
    OUTPUT='╔════════════════════════════════════════════════════════════════════════════════════════════════╗
║ This is your Login-name, Hostname, your temporary password and hard-drive decryption password. ║
║                           PLEASE WRITE THEM DOWN OR REMEMBER THEM!                             ║
╚════════════════════════════════════════════════════════════════════════════════════════════════╝\n'
    printColor "$OUTPUT" "YELLOW"

    LUKS_KEY=$(cat /mnt/home/$1/luks-temp.key)

    printColor "Login-name: $1\nHostname: $2\nTemporary user password: $3\nTemporary Hard-drive decryption password: $LUKS_KEY\n\n" "YELLOW"

    OUTPUT='╔═══════════════════════════════════════════════════════════════════════════════════╗
║ Rebooting, please set Secure-Boot in BIOS to setup mode and turn on Secure-Boot!  ║
╚═══════════════════════════════════════════════════════════════════════════════════╝'
    printColor "$OUTPUT" "CYAN"

    printColor "Press any key to reboot and continue..." CYAN
    read -r IGNORE
    systemctl reboot --firmware-setup
}

#Catches errors and stops the script early
set -eo pipefail

SCRIPT_PATH=$(dirname "$0")
cd $SCRIPT_PATH
source ./util.sh

check_parameters $1 $2

LOGIN_NAME=$1
HOSTNAME=$2

install_linux
configure_basics "$HOSTNAME"
create_user "$LOGIN_NAME"
configure_sudo
setup_uki "$LOGIN_NAME"
doReboot "$LOGIN_NAME" "$HOSTNAME" "$PASSWORD"
