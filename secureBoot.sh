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

function flipScript(){
  rm -rf /home/pascal.brus/.bashrc
  cp /home/pascal.brus/bashrc2 /home/pascal.brus/.bashrc
  rm -rf /home/pascal.brus/.bashrc2
  echo "2" > /home/pascal.brus/tmp.txt
}

function recoveryKey {

  echo "Recovery Key generieren..."
  sudo systemd-cryptenroll /dev/gpt-auto-root-luks --unlock-key-file=luks-temp.key --recovery-key > /home/pascal.brus/recovery_key.txt

  flipScript

  echo "Rebooting, to setup TPM2 correctly"
  
  #sudo systemctl reboot

}

function rollOutTPM2(){
  echo "TPM2 ausrollen..."
  $(systemd-cryptenroll --tpm2-device=auto --wipe-slot=tpm2 --tpm2-pcrs=0+7 --unlock-key-file=luks-temp.key /dev/gpt-auto-root-luks)

  echo "Delete Initial Password..."
  #systemd-cryptenroll /dev/gpt-auto-root-luks --wipe-slot=password

  #rm -rf /home/pascal.brus/.bashrc
  cp /home/pascal.brus/.bashrcBACKUP /home/pascal.brus/.bashrc

  #systenctl reboot
}

function checkForFile(){

FLAG=$(cat "/home/pascal.brus/tmp.txt")
  if [ "$FLAG" -eq 2 ] 2>/dev/null; then
    createKeysAndSign
    recoveryKey
  else
    rollOutTPM2
  fi

}
set +eo
#set -eo pipefail
#checkSetupMode
checkForFile
set +eo
