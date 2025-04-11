
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

$LOGIN_NAME=$1
$HOSTNAME=$2

configure_basics $HOSTNAME

