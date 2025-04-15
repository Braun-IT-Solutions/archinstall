#!/usr/bin/bash

function checkSetupMode(){
  sbctl status
}

function createKeysAndSign(){
  echo "Creating keys..."
  sudo sbctl create-keys
  sudo sbctl enroll-keys -m

  echo "Signing Keys.."
  sudo sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
  sudo sbctl sign -s /efi/EFI/BOOT/BOOTX64.efi
  sudo sbctl sign -s /efi/EFI/Linux/arch-linux.efi
  sudo sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi

  echo "UKI's neu generieren"
  mkinitcpio -P 
}

function recoveryKey {

  echo "Recovery Key generieren..."
  sudo systemd-cryptenroll /dev/gpt-auto-root-luks --unlock-key-file=luks-temp.key --recovery-key > /home/pascal.brus/recovery_key.txt


  echo "Rebooting, to setup TPM2 correctly"
  #sudo systemctl reboot

}

set -eo pipefail

#checkSetupMode
createKeysAndSign
recoveryKey

set +eo
