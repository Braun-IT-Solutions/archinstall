#!/usr/bin/bash
#This Script runs after user login after initial setup in "/home/USER/.bashrc"

#Checks if BIOS secureboot is in setup mode
function checkSetupMode(){
  sbctl status
}

#Creates keys, signs them and rebuilds initramfs image based on kernel packages(mkinitcpio -P)
function createKeysAndSign(){
  echo -e "\033[32mCreating keys...\033[0m"
  #Creates a set of signing keys used to sign EFI binaries
  sudo sbctl create-keys
  #Enrolls the created key into the EFI variables. 
  #"-m: Enroll UEFI vendor certificates from Microsoft into the signature database."
  #Some Services/Hrdware needs those 
  sudo sbctl enroll-keys -m

  echo "Signing Keys.."
  #Signs an EFI binary with the created key 
  #-o: output filename,
  #-s: saves key to the database
  sudo sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
  sudo sbctl sign -s /efi/EFI/BOOT/BOOTX64.efi
  sudo sbctl sign -s /efi/EFI/Linux/arch-linux.efi
  sudo sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi

  echo "UKI's neu generieren"
  #Generates initramfs image based on kernel packages 
  #"-P: re-generates all initramfs images"
  sudo mkinitcpio -P 
}

#Creates recovery key and flips script 
#("see echo "2" > /home/$USER/tmp.txt" line for more detail)
function recoveryKey() {

  echo "Recovery Key generieren..."
  #Generates recovery key into user home directory
  sudo systemd-cryptenroll /dev/gpt-auto-root-luks --unlock-key-file=luks-temp.key --recovery-key > /home/$USER/recovery_key.txt

  #replaces tmp.txt with "2" flag to make sure the script runs again after reboot from the correct point
  echo "2" > /home/$USER/tmp.txt

  #Reboot to setup TPM2 correctly
  echo -e "\033[31mRebooting, to setup TPM2 correctly\033[0m"
  read -p "Press any key to reboot and continue" IGNORE
  sudo systenctl reboot

}

#Rolls out TPM2
function rollOutTPM2(){
  echo "TPM2 ausrollen..."
  #Enables autodecrypt, 
  #Registers pcrs: 
  # 0: Core System Firmware executable code, 
  # 7: Secure Boot State,
  #needs the temporary key from "./luks-temp.key"
  $(sudo systemd-cryptenroll --tpm2-device=auto --wipe-slot=tpm2 --tpm2-pcrs=0+7 --unlock-key-file=luks-temp.key /dev/gpt-auto-root-luks)

  echo "Delete Initial Password..."
  #Deletes temporary password
  systemd-cryptenroll /dev/gpt-auto-root-luks --wipe-slot=password
  rm -rf /home/$USER/luks-temp.key

  #Deletes this Script from "/home/$USER/.bashrc",
  #restores og .bashrc and,
  #deletes tmp.txt for script toggle
  rm -rf /home/$USER/.bashrc
  cp /home/$USER/.bashrcBACKUP /home/$USER/.bashrc
  rm -rf /home/$USER/.bashrcBACKUP /home/$USER/tmp.txt


  echo -e "\033[31mRebooting to finalize TPM2 rollout\033[0m"
  read -p "Press any key to reboot and continue" IGNORE
  sudo systenctl reboot
}

#Entry point for Script, toggles depending on tmp.txt
function checkForFile(){

  FLAG=$(cat "/home/$USER/tmp.txt")
  if [ "$FLAG" -eq 1 ] 2>/dev/null; then
    createKeysAndSign
    recoveryKey
  elif [ "$FLAG" -eq 2 ] 2>/dev/null; then
    rollOutTPM2
  else
    echo "\033[31mUnexpected FLAG in tmp.txt\033[0m"
  fi

}

set +eo
checkForFile
