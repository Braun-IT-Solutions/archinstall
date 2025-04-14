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
  echo "1" > /dev/tty
  sudo sbctl sign -s /efi/EFI/BOOT/BOOTX64.efi
  echo "2" > /dev/tty
  sudo sbctl sign -s /efi/EFI/Linux/arch-linux.efi
  echo "3" > /dev/tty
  sudo sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi
  echo "4" > /dev/tty

  echo "UKI's neu generieren" > /dev/tty
  sudo mkinitcpio -P 
}

set -eo pipefail

#checkSetupMode
createKeysAndSign

./tpm2.sh