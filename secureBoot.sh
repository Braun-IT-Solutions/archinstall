#!/usr/bin/bash

function checkSetupMode(){
  sbctl status
}

function createKeysAndSign(){
  echo "Creating keys..." > /dev/tty
  sbctl create-keys
  sbctl enroll-keys -m

  echo "Signing Keys.." > /dev/tty
  sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed
  sbctl sign -s /efi/EFI/BOOT/BOOTX64.efi
  sbctl sign -s /efi/EFI/Linux/arch-linux.efi
  sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi

  echo "UKI's neu generieren" > /dev/tty
  mkinitcpio -P 
}

set -eo pipefail

#checkSetupMode
createKeysAndSign

#./tpm2.sh