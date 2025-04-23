#!/usr/bin/bash
#This Script runs after user login after initial setup in "/home/USER/.bashrc"

# Exit on error, undefined variable, and propagate pipe failures
set -euo pipefail

SCRIPT_PATH=$(dirname "$0")
cd "$SCRIPT_PATH"

source ./util.sh

TEMP_TXT="$HOME/tmp.txt"
RECOVERY_KEY_TXT="$HOME/recovery_key.txt"
LUKS_TEMP_KEY="$HOME/luks-temp.key"
LUKS_DEVICE="/dev/gpt-auto-root-luks"

# $1 message
#write info message and ask for input to reboot
function doReboot() {
  printColor "$1" CYAN
  printColor "Press enter to reboot..." CYAN
  read -r IGNORE
  reboot
}

# $1 new flag
function setFlagTo() {
  #replaces tmp.txt with flag value to make sure the script runs again after reboot from the correct point
  echo "$1" >"$TEMP_TXT"
}

#Checks if BIOS secureboot is in setup mode
function checkSetupMode() {
  if sbctl status | grep -q "Setup Mode: Enabled"; then
    return 0
  elif sbctl status | grep -q "Setup Mode"; then
    printColor "Secureboot is not in setup mode" RED
    exit 1
  else
    printColor "Failed to check Secure Boot status" RED
    exit 1
  fi
}

#Creates keys, signs them and rebuilds initramfs image based on kernel packages(mkinitcpio -P)
function createKeysAndSign() {
  printColor "Creating keys..." GREEN
  #Creates a set of signing keys used to sign EFI binaries
  sudo sbctl create-keys || {
    printColor "Failed to create Secure Boot keys" RED
    return 1
  }

  printColor "Created keys..." GREEN
  printColor "Enrolling keys..." GREEN
  #Enrolls the created key into the EFI variables.
  #"-m: Enroll UEFI vendor certificates from Microsoft into the signature database."
  #Some Services/Hardware needs those
  sudo sbctl enroll-keys -m || {
    printColor "Failed to enroll Secure Boot keys" RED
    return 1
  }

  printColor "Enrolled keys..." GREEN

  printColor "Signing Keys..." GREEN
  #Signs EFI binaries with the created keys
  #-o: output filename,
  #-s: saves key to the database
  sudo sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi || {
    printColor "Failed to sign systemd-bootx64.efi" RED
    return 1
  }

  sudo sbctl sign -s /efi/EFI/BOOT/BOOTX64.efi
  sudo sbctl sign -s /efi/EFI/Linux/arch-linux.efi
  sudo sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi

  printColor "Signed Keys..." GREEN
  printColor "Generating new UKI's..." GREEN
  #Generates initramfs image based on kernel packages
  #"-P: re-generates all initramfs images"
  sudo mkinitcpio -P || {
    printColor "Failed to generate initramfs images" RED
    return 1
  }
  printColor "Generated UKI's..." GREEN
}

#create and set recovery key
function setRecoveryKey() {
  printColor "Generate Recovery Key..." GREEN

  #Generates recovery key into user home directory
  if ! sudo systemd-cryptenroll "$LUKS_DEVICE" --unlock-key-file="$LUKS_TEMP_KEY" --recovery-key >"$RECOVERY_KEY_TXT"; then
    printColor "Failed to generate recovery key" RED
    return 1
  fi

  sudo chown "$USER:$USER" "$RECOVERY_KEY_TXT"
  chmod 600 "$RECOVERY_KEY_TXT"

  printColor "Recovery Key generated..." GREEN
}

function cleanUp() {
  printColor "Delete temporary files..." GREEN
  #Deletes this Script from "$HOME/.bashrc",
  #restores og .bashrc and,
  #deletes tmp.txt for script toggle
  #deletes util script

  # Securely remove sensitive file
  shred -u "$LUKS_TEMP_KEY" 2>/dev/null || rm -f "$LUKS_TEMP_KEY"

  # Restore original .bashrc if backup exists
  rm -f "$HOME/.bashrc"
  cp "$HOME/.bashrcBACKUP" "$HOME/.bashrc"
  rm -f "$HOME/.bashrcBACKUP"

  # Remove other temporary files
  rm -f "$HOME/tmp.txt" "$HOME/util.sh"

  printColor "Deleted temporary files..." GREEN
}

function rollingTPM2() {
  printColor "Rolling TPM2..." GREEN
  #Enables autodecrypt,
  #Registers pcrs:
  # 0: Core System Firmware executable code,
  # 7: Secure Boot State,
  #needs the temporary key from "./luks-temp.key"
  $(sudo systemd-cryptenroll --tpm2-device=auto --wipe-slot=tpm2 --tpm2-pcrs=0+7 --unlock-key-file="$LUKS_TEMP_KEY" "$LUKS_DEVICE")

  printColor "Rolled TPM2..." GREEN
  printColor "Deleting initial luks password..." GREEN

  #Deletes temporary password
  if ! sudo systemd-cryptenroll "$LUKS_DEVICE" --wipe-slot=password; then
    printColor "Failed to wipe temporary LUKS password" RED
    return 1
  fi

  printColor "Deleted initial luks password..." GREEN
}

function sudoRequirePW() {
  printColor "Configuring sudo to require password..." GREEN
  # Create a temporary file for safer sudoers editing
  SUDOERS_TMP=$(mktemp)
  sudo cp /etc/sudoers "$SUDOERS_TMP"

  # Remove the comment marker from password-requiring line
  sudo sed -i -e '/^[[:space:]]*#[[:space:]]*%wheel[[:space:]]*ALL=(ALL:ALL)[[:space:]]*ALL/s/^[[:space:]]*#[[:space:]]*//' "$SUDOERS_TMP"
  # Comment out the NOPASSWD line
  sudo sed -i -e '/^[[:space:]]*%wheel[[:space:]]*ALL=(ALL:ALL)[[:space:]]*NOPASSWD:[[:space:]]*ALL/s/^/# /' "$SUDOERS_TMP"

  # Verify the changes
  if sudo grep -qE '^[[:space:]]*%wheel[[:space:]]*ALL=\(ALL:ALL\)[[:space:]]*ALL' "$SUDOERS_TMP" &&
    sudo grep -qE '^[[:space:]]*#[[:space:]]*%wheel[[:space:]]*ALL=\(ALL:ALL\)[[:space:]]*NOPASSWD:[[:space:]]*ALL' "$SUDOERS_TMP"; then
    printColor "Successfully configured sudo to require password" GREEN
  else
    printColor "Warning: Changes applied but verification failed. Please check /etc/sudoers manually." YELLOW
  fi

  # Check syntax before applying changes
  if sudo visudo -c -f "$SUDOERS_TMP" >/dev/null 2>&1; then
    # Apply the changes if syntax is correct
    sudo cp "$SUDOERS_TMP" /etc/sudoers
  else
    printColor "Error: Invalid sudoers syntax detected. No changes were made." RED
  fi

  # Clean up temporary file
  sudo rm -f "$SUDOERS_TMP"
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
      # Use here-string to avoid exposing password in process list
      printf "%s:%s" "$USER" "$NEW_PASSWORD" | sudo chpasswd
      printColor "Set user password" GREEN
      break
    else
      printColor "Passwords do not match. Please try again." RED
      unset NEW_PASSWORD REPEAT_PASSWORD # Clear variables containing passwords
    fi
  done
}

# Main script execution
checkSetupMode

# Ensure user file permissions
sudo chown "$USER:$USER" "$HOME"/* 2>/dev/null || true  # Non-fatal if empty
sudo chown "$USER:$USER" "$HOME"/.* 2>/dev/null || true # Non-fatal if no dotfiles

# Check if temp file exists
if [[ ! -f "$TEMP_TXT" ]]; then
  printColor "Error: Missing $TEMP_TXT file!" RED
  exit 1
fi

# Read the flag for the next step to run
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
  OUTPUT="╔═════════════════════════════════════════════════════╗\n\
║ Secure the luks recovery key in ($RECOVERY_KEY_TXT) ║\n\
║ Make sure to store it safely and securely!          ║\n\
╚═════════════════════════════════════════════════════╝\n"
  printColor "$OUTPUT" YELLOW
  doReboot "Script is done after reboot"
else
  printColor "Unexpected FLAG value ($FLAG) in $TEMP_TXT" RED
  printColor "Expected values are 1 or 2. Please restore a correct value to continue." RED
  exit 1
fi
