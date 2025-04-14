#!/usr/bin/bash

function checkSetupMode(){
  sbctl status
}

function createKeysAndSign(){
  echo "Creating keys..." > /dev/tty
  sbctl create-keys
  sbctl enroll-keys -m

  echo "Signing Keys.." > /dev/tty
  sudo sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
  sudo sbctl sign -s /efi/EFI/BOOT/BOOTX64.efi
  sudo sbctl sign -s /efi/EFI/Linux/arch-linux.efi
  sudo sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi

  echo "UKI's neu generieren" > /dev/tty
  sudo mkinitcpio -P 
}

function recoveryKey {

  echo "Recovery Key generieren..." > /dev/tty
  sudo systemd-cryptenroll /dev/gpt-auto-root-luks --recovery-key > ~/recovery_key.txt

  echo "TPM2 ausrollen..." > /dev/tty
  sudo systemd-cryptenroll --tpm2-device=auto --wipe-slot=tpm2 --tpm2-pcrs=0+7 /dev/gpt-auto-root-luks

  echo "Delete Initial Password..." > /dev/tty
  #systemd-cryptenroll /dev/gpt-auto-root-luks --wipe-slot=password

}


set -eo pipefail

#checkSetupMode
createKeysAndSign
recoveryKey