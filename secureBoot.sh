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
  sudo mkinitcpio -P 
}

function recoveryKey() {

  echo "Recovery Key generieren..."
  sudo systemd-cryptenroll /dev/gpt-auto-root-luks --unlock-key-file=luks-temp.key --recovery-key > /home/pascal.brus/recovery_key.txt

  echo "2" > /home/pascal.brus/tmp.txt

  echo "Rebooting, to setup TPM2 correctly"
  
  #sudo systemctl reboot

}

function rollOutTPM2(){
  echo "TPM2 ausrollen..."
  $(sudo systemd-cryptenroll --tpm2-device=auto --wipe-slot=tpm2 --tpm2-pcrs=0+7 --unlock-key-file=luks-temp.key /dev/gpt-auto-root-luks)

  echo "Delete Initial Password..."
  systemd-cryptenroll /dev/gpt-auto-root-luks --wipe-slot=password

  rm -rf /home/pascal.brus/.bashrc
  cp /home/pascal.brus/.bashrcBACKUP /home/pascal.brus/.bashrc
  rm -rf /home/pascal.brus/.bashrcBACKUP /home/pascal.brus/luks-temp.key /home/pascal.brus/tmp.txt


  #systenctl reboot
}

function checkForFile(){

FLAG=$(cat "/home/pascal.brus/tmp.txt")
  if [ "$FLAG" -eq 1 ] 2>/dev/null; then
    createKeysAndSign
    recoveryKey
  elif [ "$FLAG" -eq 2 ] 2>/dev/null; then
    rollOutTPM2
  else
    echo "Unexpected FLAG in tmp.txt"
  fi

}
set +eo
checkForFile
