
#Checks for both parameters
#1: Login-name
#2: Hostname
check_parameters(){
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
    OUTPUT="Finding fastest mirrors..."
    printColor "$OUTPUT" GREEN
    #Retrieves and filters the latest pacman mirror list
    reflector --country DE --age 24 --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist

    OUTPUT="Installing basic linux..."
    printColor "$OUTPUT" GREEN
    #Packages to install
    PACKAGES="base base-devel linux linux-firmware git nano cryptsetup amd-ucode sbctl sudo htop btop nvtop dhcpcd"
    #Comes preinstalled with arch, designed to create new system installations
    #-K initializes a new pacman keyring
    pacstrap -K /mnt $PACKAGES
}

#Generates locales, german keyboard and hostname
function configure_basics() {
    
    OUTPUT="Settings timezone..."
    printColor "$OUTPUT" GREEN
    #Sets Timezone Berlin
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

    OUTPUT="Setting hardware clock..."
    printColor "$OUTPUT" GREEN
    #Sets the hardwareclock to current system time
    arch-chroot /mnt hwclock --systohc

    OUTPUT="Setting locales..."
    printColor "$OUTPUT" GREEN
    
    #Setting german locales and EN-USA as fallback
    sed -i -e "/^#"de_DE.UTF-8"/s/^#//" /mnt/etc/locale.gen
    sed -i -e "/^#"en_US.UTF-8"/s/^#//" /mnt/etc/locale.gen


    OUTPUT="Setting keymap..."
    printColor "$OUTPUT" GREEN
    #Sets german keyboard
    echo "KEYMAP=de-latin1" > /mnt/etc/vconsole.conf

    OUTPUT="Setting hostname..."
    printColor "$OUTPUT" GREEN
    #sets hostname
    echo $1 > /mnt/etc/hostname

    OUTPUT="Generating locales..."
    printColor "$OUTPUT" GREEN
    #Generates locales
    arch-chroot /mnt locale-gen
}

#Setup for user with "$LOGIN_NAME"
function create_user() {
    #$1 = $LOGIN_NAME
    DEFAULT_PASSWORD="root"

    OUTPUT="Creating user..."
    printColor "$OUTPUT" GREEN
    arch-chroot /mnt useradd -G wheel -m $1
    echo $DEFAULT_PASSWORD | arch-chroot /mnt passwd $1 --stdin
    
    OUTPUT="Your initial password is \033[96m$DEFAULT_PASSWORD"
    printColor "$OUTPUT" CYAN
    sleep 5
}

#Configures sudo to not need password
function configure_sudo() {
    OUTPUT="Configuring sudo..."
    printColor "$OUTPUT" GREEN
    sed -i -e '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' /mnt/etc/sudoers
}

#Enables systemd & dhcpcd services
function enable_services() {
    OUTPUT="Enabling systemd services..."
    printColor "$OUTPUT" GREEN
    systemctl --root /mnt enable systemd-resolved systemd-timesyncd dhcpcd
}

#Sets unified kernel images and generates them
function setup_uki() {
    OUTPUT="Setting up UKI..."
    printColor "$OUTPUT" GREEN

    #Sets kernel parameters 
    #"rw: Mount root device read-write on boot"
    echo "rw" > /mnt/etc/kernel/cmdline
    mkdir -p /mnt/efi/EFI/Linux

    OUTPUT="Setting mkinitcpio hooks..."
    printColor "$OUTPUT" GREEN
    HOOKS="base systemd autodetect modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck"
    #Setting our hooks for mkinitcpio
    sed -i -e "s/^HOOKS=.*/HOOKS=($HOOKS)/g" /mnt/etc/mkinitcpio.conf

    OUTPUT="Enabling UKI..."
    printColor "$OUTPUT" GREEN
    #Enabling our UKIs
    sed -i -e "s/^default_config=/#default_config=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^default_image=/#default_image=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#default_uki=/default_uki=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#default_options=/default_options=/g" /mnt/etc/mkinitcpio.d/linux.preset

    sed -i -e "s/^fallback_config=/#fallback_config=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^fallback_image=/#fallback_image=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#fallback_uki=/fallback_uki=/g" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i -e "s/^#fallback_options=/fallback_options=/g" /mnt/etc/mkinitcpio.d/linux.preset

    OUTPUT="Generating UKI..."
    printColor "$OUTPUT" GREEN
    #Generates initramfs image based on kernel packages 
    #"-P: re-generates all initramfs images"
    arch-chroot /mnt mkinitcpio -P

    OUTPUT="Installing bootloader..."
    printColor "$OUTPUT" GREEN
    #Install EFI bootloader 
    #"--esp-path=: path to our efi partition"
    arch-chroot /mnt bootctl install --esp-path=/efi


    enable_services

    sync

    OUTPUT="Setting up temp files..."
    printColor "$OUTPUT" GREEN

    #$1 = $LOGIN_NAME
    cp /mnt/home/$1/.bashrc /mnt/home/$1/.bashrcBACKUP
    rm -rf /mnt/home/$1/.bashrc

    cat secureBoot.sh > /mnt/home/$1/.bashrc
    cat util.sh > /mnt/home/$1/util.sh
    echo "1" > /mnt/home/$1/tmp.txt

    cp luks-temp.key /mnt/home/$1/luks-temp.key
    chmod 400 /mnt/home/$1/luks-temp.key


OUTPUT='╔═══════════════════════════════════════════════════════════════════════════════════╗
║ Rebooting, please set Secure-Boot in BIOS to setup mode! And tsurn on Secure-Boot ║
╚═══════════════════════════════════════════════════════════════════════════════════╝'
    printColor "$OUTPUT" "CYAN"

    OUTPUT="Press any key to reboot and continue..."
    printColor "$OUTPUT" CYAN
    read -p "" IGNORE
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

