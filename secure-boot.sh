#!/usr/bin/bash
#This Script runs after user login after initial setup in "/home/USER/.bashrc"

TEMP_TXT=$HOME/tmp.txt
RECOVERY_KEY_TXT=$HOME/recovery_key.txt

#write info message and ask for input to reboot
function doReboot() {
  printColor "$1" CYAN
  printColor "Press enter to reboot..." CYAN
  read -r IGNORE
  reboot
}

function setFlagTo() {
  #replaces tmp.txt with "2" flag to make sure the script runs again after reboot from the correct point
  echo "$1" >$TEMP_TXT
}

#Checks if BIOS secureboot is in setup mode
function checkSetupMode() {
  sbctl status
}

#Creates keys, signs them and rebuilds initramfs image based on kernel packages(mkinitcpio -P)
function createKeysAndSign() {
  printColor "Creating keys..." GREEN
  #Creates a set of signing keys used to sign EFI binaries
  sudo sbctl create-keys

  printColor "Created keys..." GREEN
  printColor "Enrolling keys..." GREEN
  #Enrolls the created key into the EFI variables.
  #"-m: Enroll UEFI vendor certificates from Microsoft into the signature database."
  #Some Services/Hrdware needs those
  sudo sbctl enroll-keys -m

  printColor "Enrolled keys..." GREEN

  printColor "Signing Keys..." GREEN
  #Signs an EFI binary with the created key
  #-o: output filename,
  #-s: saves key to the database
  sudo sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
  sudo sbctl sign -s /efi/EFI/BOOT/BOOTX64.efi
  sudo sbctl sign -s /efi/EFI/Linux/arch-linux.efi
  sudo sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi

  printColor "Siged Keys..." GREEN
  printColor "Generating new UKI's..." GREEN
  #Generates initramfs image based on kernel packages
  #"-P: re-generates all initramfs images"
  sudo mkinitcpio -P
  printColor "Generated UKI's..." GREEN
}

#create and set recovery key
function setRecoveryKey() {
  printColor "Generate Recovery Key..." GREEN

  #Generates recovery key into user home directory
  sudo systemd-cryptenroll /dev/gpt-auto-root-luks --unlock-key-file=luks-temp.key --recovery-key >$RECOVERY_KEY_TXT
  sudo chown $USER:$USER $RECOVERY_KEY_TXT

  printColor "Recovery Key generated..." GREEN
}

function cleanUp() {
  printColor "Delete temporary files..." GREEN
  #Deletes this Script from "$HOME/.bashrc",
  #restores og .bashrc and,
  #deletes tmp.txt for script toggle
  #deletes util script
  rm -rf $HOME/.bashrc
  cp $HOME/.bashrcBACKUP $HOME/.bashrc
  rm -rf $HOME/.bashrcBACKUP $HOME/tmp.txt $HOME/util.sh

  printColor "Deleted temporary files..." GREEN
}

function rollingTPM2() {
  printColor "Rolling TPM2.." GREEN
  #Enables autodecrypt,
  #Registers pcrs:
  # 0: Core System Firmware executable code,
  # 7: Secure Boot State,
  #needs the temporary key from "./luks-temp.key"
  $(sudo systemd-cryptenroll --tpm2-device=auto --wipe-slot=tpm2 --tpm2-pcrs=0+7 --unlock-key-file=luks-temp.key /dev/gpt-auto-root-luks)

  printColor "Rolled TPM2.." GREEN
  printColor "Deleting initial luks password..." GREEN
  #Deletes temporary password
  sudo systemd-cryptenroll /dev/gpt-auto-root-luks --wipe-slot=password
  rm -rf $HOME/luks-temp.key

  printColor "Deleted initial luks password..." GREEN
}

function sudoRequirePW() {
  sudo sed -i -e '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers
  sudo sed -i -e '/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^/# /' /etc/sudoers
}

function setNewUserPassword() {
  #Loop until passwords match
  while true; do
    printColor "Please enter a new secure password for your user: " CYAN
    #use -s to hide typed keys
    read -r -s -p "Password: " NEW_PASSWORD
    echo
    read -r -s -p "Repeat: " REPEAT_PASSWORD
    echo

    if [ "$NEW_PASSWORD" = "$REPEAT_PASSWORD" ]; then
      echo $USER:$NEW_PASSWORD | chpasswd
      printColor "Set user password" GREEN
      break
    else
      printColor "Passwords do not match. Please try again." RED
    fi
  done
}

set -eo pipefail

SCRIPT_PATH=$(dirname "$0")
cd $SCRIPT_PATH
source ./util.sh

#ensue user file permissions
sudo chown $USER:$USER $HOME/*
sudo chown $USER:$USER $HOME/.*

#read the flag for the next step to run
FLAG=$(cat "$TEMP_TXT")
if [ "$FLAG" -eq 1 ] 2>/dev/null; then
  createKeysAndSign
  setRecoveryKey
  setFlagTo "2"
  doReboot "Script continues after reboot"
elif [ "$FLAG" -eq 2 ] 2>/dev/null; then
  rollingTPM2
  setNewUserPassword
  sudoRequirePW
  cleanUp
  printColor "Secure the luks recovery key in ($RECOVERY_KEY_TXT)"
  doReboot "Script is done after reboot"
else
  printColor "Unexpected FLAG in tmp.txt" RED
fi
