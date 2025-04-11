
function configure_basics() {
    echo "Settings timezone"
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

    echo "Setting hardware clock"
    arch-chroot /mnt hwclock --systohc

    echo "Setting locales"
    sed -i -e "/^#"de_DE.UTF-8"/s/^#//" /mnt/etc/local.gen
    sed -i -e "/^#"en_US.UTF-8"/s/^#//" /mnt/etc/local.gen

    echo "Setting keymap"
    echo "KEYMAP=de-latin1" > /mnt/etc/vconsole.conf

    echo "Setting hostname"
    echo $1 > /mnt/etc/hostname

    echo "Generating locales"
    arch-chroot /mnt locale-gen
}

function install_linux() {
    echo "Finding fastest mirrors..."
    reflector --country DE --age 24 --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist

    echo "Installing basic linux..."
    PACKAGES="base base-devel linux linux-firmware git nano cryptsetup amd-ucode sbctl sudo htop btop nvtop dhcpcd"
    pacstrap -K /mnt $PACKAGES
}

function create_user() {
    DEFAULT_PASSWORD="root"

    echo "Creating user..."
    arch-chroot /mnt useradd -G wheel -m $1
    echo $DEFAULT_PASSWORD | arch-chroot /mnt passwd $1 --stdin
    
    echo -e "\033[31mYour initial password is \033[1m$DEFAULT_PASSWORD\033[0m"
    sleep 5
}

function configure_sudo() {
    echo "Configuring sudo..."
    sed -i -e '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' /mnt/etc/sudoers
}

function setup_uki() {
    echo "Setting up UKI"

    echo "rw" > /mnt/etc/kernel/cmdline
    mkdir -p /mnt/efi/EFI/Linux

    echo "Setting mkinitcpio hooks..."
    HOOKS="base systemd autodetect modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck"
    sed -i -e "s/^HOOKS=.*/HOOKS=(${HOOKS})/g" /mnt/etc/mkinitcpio.conf

    echo "Enabling UKI"
    sed -i -e "s/^default_config=/#default_config=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^default_image=/#default_image=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#default_uki=/default_uki=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#default_options=/default_options=/g" /mnt/etc/mkinitcpio.d/linux.preset

    sed -i -e "s/^fallback_config=/#fallback_config=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^fallback_image=/#fallback_image=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#fallback_uki=/fallback_uki=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#fallback_options=/fallback_options=/g" /mnt/etc/mkinitcpio.d/linux.preset

    echo "Generating UKI..."
    arch-chroot /mnt mkinitcpio -P

    echo "Installing bootloader..."
    arch-chroot /mnt bootctl install --esp-path=/efi

    sync

    echo "Rebooting, please set Secure Boot in BIOS to setup mode!"
    read -p "Press any key to reboot and continue" IGNORE

    systemctl reboot --firmware-setup
}

function enable_services() {
    echo "Enabling systemd services"
    systemctl --root /mnt enable systemd-resolved systemd-timesyncd dhcpcd
}

LOGIN_NAME=$1
HOSTNAME=$2

configure_basics "$HOSTNAME"
install_linux
create_user "$LOGIN_NAME"
configure_sudo
setup_uki
enable_services
