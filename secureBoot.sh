#!/usr/bin/bash

function checkSetupMode(){
  sbctl status
}

function createKeysAndSign(){
  echo "Creating keys..." > /dev/tty
  sbctl create-keys
  sbctl enroll-keys -m

  echo "Signing Keys.." > /dev/tty
  sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
  sbctl sign -s /efi/EFI/BOOT/BOOTX64.efi
  sbctl sign -s /efi/EFI/Linux/arch-linux.efi
  sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi

  echo "UKI's neu generieren" > /dev/tty
  mkinitcpio -P 
}

function recoveryKey {

  echo "Recovery Key generieren..." > /dev/tty
  systemd-cryptenroll /dev/gpt-auto-root-luks --unlock-key-file=luks-temp.key --recovery-key > recovery_key.txt


  echo "Rebooting, to setup TPM2 correctly"
  read -p "Press any key to reboot and continue" IGNORE

  systemctl reboot --firmware-setup

}


set -eo pipefail

#checkSetupMode
createKeysAndSign
recoveryKey