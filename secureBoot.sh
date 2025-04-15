#!/usr/bin/bash

function checkSetupMode(){
  sbctl status
}

function createKeysAndSign(){
  echo "Creating keys..."
  sbctl create-keys
  sbctl enroll-keys -m

  echo "Signing Keys.."
  sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
  sbctl sign -s /efi/EFI/BOOT/BOOTX64.efi
  sbctl sign -s /efi/EFI/Linux/arch-linux.efi
  sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi

  echo "UKI's neu generieren"
  mkinitcpio -P 
}

function recoveryKey {

  echo "Recovery Key generieren..."
  systemd-cryptenroll /dev/gpt-auto-root-luks --unlock-key-file=luks-temp.key --recovery-key > /home/pascal.brus/recovery_key.txt



  systemctl enable secureBoot2.service


  echo "Rebooting, to setup TPM2 correctly"
  systemctl reboot --firmware-setup

}


set -eo pipefail

#checkSetupMode
createKeysAndSign
recoveryKey