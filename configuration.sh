#Installs basic packages and system files
function install_linux() {
    echo "Finding fastest mirrors..."
    #Retrieves and filters the latest pacman mirror list
    reflector --country DE --age 24 --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist

    echo "Installing basic linux..."
    #Packages to install
    PACKAGES="base base-devel linux linux-firmware git nano cryptsetup amd-ucode sbctl sudo htop btop nvtop dhcpcd"
    #Comes preinstalled with arch, designed to create new system installations
    #-K initializes a new pacman keyring
    pacstrap -K /mnt $PACKAGES
}

#Generates locales, german keyboard and hostname
function configure_basics() {
    echo "Settings timezone"
    #Sets Timezone Berlin
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

    echo "Setting hardware clock"
    #Sets the hardwareclock to current system time
    arch-chroot /mnt hwclock --systohc

    echo "Setting locales"
    #Setting german locales and EN-USA as fallback
    sed -i -e "/^#"de_DE.UTF-8"/s/^#//" /mnt/etc/locale.gen
    sed -i -e "/^#"en_US.UTF-8"/s/^#//" /mnt/etc/locale.gen

    echo "Setting keymap"
    #Sets german keyboard
    echo "KEYMAP=de-latin1" > /mnt/etc/vconsole.conf

    echo "Setting hostname"#
    #sets hostname
    echo $1 > /mnt/etc/hostname

    echo "Generating locales"
    #Generates locales
    arch-chroot /mnt locale-gen
}

#Setup for user with "$LOGIN_NAME"
function create_user() {
    #$1 = $LOGIN_NAME
    DEFAULT_PASSWORD="root"

    echo "Creating user..."
    arch-chroot /mnt useradd -G wheel -m $1
    echo $DEFAULT_PASSWORD | arch-chroot /mnt passwd $1 --stdin
    
    echo -e "\033[31mYour initial password is \033[1m$DEFAULT_PASSWORD\033[0m\n"
    sleep 5
}

#Configures sudo to not need password
function configure_sudo() {
    echo "Configuring sudo..."
    sed -i -e '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' /mnt/etc/sudoers
}

#Enables systemd & dhcpcd services
function enable_services() {
    echo "Enabling systemd services"
    systemctl --root /mnt enable systemd-resolved systemd-timesyncd dhcpcd
}

#Sets unified kernel images and generates them
function setup_uki() {
    echo "Setting up UKI"

    #Sets kernel parameters 
    #"rw: Mount root device read-write on boot"
    echo "rw" > /mnt/etc/kernel/cmdline
    mkdir -p /mnt/efi/EFI/Linux

    echo "Setting mkinitcpio hooks..."
    HOOKS="base systemd autodetect modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck"
    #Setting our hooks for mkinitcpio
    sed -i -e "s/^HOOKS=.*/HOOKS=($HOOKS)/g" /mnt/etc/mkinitcpio.conf

    echo "Enabling UKI"
    #Enabling our UKIs
    sed -i -e "s/^default_config=/#default_config=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^default_image=/#default_image=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#default_uki=/default_uki=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#default_options=/default_options=/g" /mnt/etc/mkinitcpio.d/linux.preset

    sed -i -e "s/^fallback_config=/#fallback_config=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^fallback_image=/#fallback_image=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#fallback_uki=/fallback_uki=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#fallback_options=/fallback_options=/g" /mnt/etc/mkinitcpio.d/linux.preset

    echo "Generating UKI..."
    #Generates initramfs image based on kernel packages 
    #"-P: re-generates all initramfs images"
    arch-chroot /mnt mkinitcpio -P

    echo "Installing bootloader..."
    #Install EFI bootloader 
    #"--esp-path=: path to our efi partition"
    arch-chroot /mnt bootctl install --esp-path=/efi


    enable_services

    sync

    cp /mnt/home/$USER/.bashrc /mnt/home/$USER/.bashrcBACKUP
    rm -rf /mnt/home/$USER/.bashrc

    cat secureBoot.sh > /mnt/home/$USER/.bashrc
    echo "1" > /mnt/home/$USER/tmp.txt

    cp luks-temp.key /mnt/home/$USER/luks-temp.key
    chmod go-r luks-temp.key


    echo -e "\033[31mRebooting, please set Secure Boot in BIOS to setup mode! And Turn on SecureBoot"
    echo -e "\033[31mRebooting, please set Secure Boot in BIOS to setup mode! And Turn on SecureBoot"
    echo -e "\033[31mRebooting, please set Secure Boot in BIOS to setup mode! And Turn on SecureBoot"

    read -p "Press any key to reboot and continue" IGNORE
    systemctl reboot --firmware-setup
}

#Catches errors and stops the script early
set -eo pipefail

LOGIN_NAME=$1
HOSTNAME=$2

install_linux
configure_basics "$HOSTNAME"
create_user "$LOGIN_NAME"
configure_sudo
setup_uki

