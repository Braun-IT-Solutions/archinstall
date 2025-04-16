#!/usr/bin/bash
#This Script runs after user login after initial setup in "/home/USER/.bashrc"

#Checks if BIOS secureboot is in setup mode
function checkSetupMode(){
  sbctl status
}

#Creates keys, signs them and rebuilds initramfs image based on kernel packages(mkinitcpio -P)
function createKeysAndSign(){
  OUTPUT="Creating keys..."
  printColor "$OUTPUT" GREEN
  #Creates a set of signing keys used to sign EFI binaries
  sudo sbctl create-keys
  #Enrolls the created key into the EFI variables. 
  #"-m: Enroll UEFI vendor certificates from Microsoft into the signature database."
  #Some Services/Hrdware needs those 
  sudo sbctl enroll-keys -m

  OUTPUT="Signing Keys..."
  printColor "$OUTPUT" GREEN
  #Signs an EFI binary with the created key 
  #-o: output filename,
  #-s: saves key to the database
  sudo sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
  sudo sbctl sign -s /efi/EFI/BOOT/BOOTX64.efi
  sudo sbctl sign -s /efi/EFI/Linux/arch-linux.efi
  sudo sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi

  OUTPUT="UKI's neu generieren..."
  printColor "$OUTPUT" GREEN
  #Generates initramfs image based on kernel packages 
  #"-P: re-generates all initramfs images"
  sudo mkinitcpio -P 
}

#Creates recovery key and flips script 
#("see echo "2" > /home/$USER/tmp.txt" line for more detail)
function recoveryKey() {

  OUTPUT="Generate Recovery Key..."
  printColor "$OUTPUT" GREEN
  #Generates recovery key into user home directory
  sudo systemd-cryptenroll /dev/gpt-auto-root-luks --unlock-key-file=luks-temp.key --recovery-key > /home/$USER/recovery_key.txt


  #replaces tmp.txt with "2" flag to make sure the script runs again after reboot from the correct point
  chown $USER:$USER /mnt/home/$USER/tmp.txt
  echo "2" > /home/$USER/tmp.txt

  #Reboot to setup TPM2 correctly
  OUTPUT="Rebooting, to setup TPM2 correctly..."
  printColor "$OUTPUT" GREEN


  OUTPUT="Press any key to reboot and continue..."
  printColor "$OUTPUT" CYAN
  read -p "" IGNORE
  sudo systemctl reboot

}

#Rolls out TPM2
function rollOutTPM2(){
  OUTPUT="TPM2 ausrollen..."
  printColor "$OUTPUT" GREEN
  #Enables autodecrypt, 
  #Registers pcrs: 
  # 0: Core System Firmware executable code, 
  # 7: Secure Boot State,
  #needs the temporary key from "./luks-temp.key"
  $(sudo systemd-cryptenroll --tpm2-device=auto --wipe-slot=tpm2 --tpm2-pcrs=0+7 --unlock-key-file=luks-temp.key /dev/gpt-auto-root-luks)

  OUTPUT="Delete Initial Password..."
  printColor "$OUTPUT" GREEN
  #Deletes temporary password
  systemd-cryptenroll /dev/gpt-auto-root-luks --wipe-slot=password
  rm -rf /home/$USER/luks-temp.key


  OUTPUT="Delete temporary files..."
  printColor "$OUTPUT" GREEN
  #Deletes this Script from "/home/$USER/.bashrc",
  #restores og .bashrc and,
  #deletes tmp.txt for script toggle
  #deletes util script
  rm -rf /home/$USER/.bashrc
  cp /home/$USER/.bashrcBACKUP /home/$USER/.bashrc
  sudo rm -rf /home/$USER/.bashrcBACKUP /home/$USER/tmp.txt /home/$USER/util.sh

  #Give User filespermissions back after editing them with root
  OUTPUT="Setting file permissions..."
  printColor "$OUTPUT" GREEN
  sudo chown $USER:$USER /home/$USER/*
  sudo chown $USER:$USER /home/$USER/.*


  OUTPUT="Rebooting to finalize TPM2 rollout..."
  printColor "$OUTPUT" GREEN

  OUTPUT="Press any key to reboot and continue..."
  printColor "$OUTPUT" CYAN
  read -p "" IGNORE
  sudo systemctl reboot
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
    OUTPUT="Unexpected FLAG in tmp.txt"
    printColor "$OUTPUT" RED
  
  fi

}

set +eo

SCRIPT_PATH=$(dirname "$0")
cd $SCRIPT_PATH
source ./util.sh

checkForFile
