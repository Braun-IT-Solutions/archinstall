#!/usr/bin/bash

# Catches errors and stops the script early
set -eo pipefail

SCRIPT_PATH=$(dirname "$0")
cd "$SCRIPT_PATH"
source ./util.sh

echo -e '\n\n $$$$$$$\  $$$$$$\ $$$$$$$$\  $$$$$$\' "\n" \
    '$$  __$$\ \_$$  _|\__$$  __|$$  __$$\' "\n" \
    '$$ |  $$ |  $$ |     $$ |   $$ /  \__|' "\n" \
    '$$$$$$$\ |  $$ |     $$ |   \$$$$$$\' "\n" \
    '$$  __$$\   $$ |     $$ |    \____$$\' "\n" \
    '$$ |  $$ |  $$ |     $$ |   $$\   $$ |' "\n" \
    '$$$$$$$  |$$$$$$\    $$ |   \$$$$$$  |' "\n" \
    '\_______/ \______|   \__|    \______/'
echo -e "\nWelcome to BITS archinstall\n"

DEFAULT_PASSWORD="root"
#Setup for Login-name and Hostname for use in ./configuration
printColor "Your first name (all lowercase):" "CYAN"
read -r FIRST_NAME

printColor "Your last name (all lowercase):" "CYAN"
read -r LAST_NAME

printColor "Your lucky number (just choose one):" "CYAN"
read -r LUCKY_NUMBER

LOGIN_NAME="$FIRST_NAME.$LAST_NAME"
printColor "Login name: $LOGIN_NAME" GREEN

INITIALS="${FIRST_NAME:0:1}${LAST_NAME:0:1}"
HOSTNAME="AXD-${INITIALS^^}${LUCKY_NUMBER}"
printColor "Hostname: $HOSTNAME" GREEN
printColor "Continue with enter..." CYAN
read -r IGNORE

# run setup scripts
./partition.sh
./configuration.sh $LOGIN_NAME $HOSTNAME $DEFAULT_PASSWORD

# inform user and ask for reboot
OUTPUT='╔════════════════════════════════════════════════════════════════════════════════════════════════╗
║ This is your Login-name, Hostname, your temporary password and hard-drive decryption password. ║
║                           PLEASE WRITE THEM DOWN OR REMEMBER THEM!                             ║
╚════════════════════════════════════════════════════════════════════════════════════════════════╝\n'
printColor "$OUTPUT" "YELLOW"

LUKS_KEY=$(cat /mnt/home/$LOGIN_NAME/luks-temp.key)

printColor "Login-name: $LOGIN_NAME\nHostname: $HOSTNAME\nTemporary user password: $DEFAULT_PASSWORD\nTemporary Hard-drive decryption password: $LUKS_KEY\n\n" "YELLOW"

OUTPUT='╔═══════════════════════════════════════════════════════════════════════════════════╗
║ Rebooting, please set Secure-Boot in BIOS to setup mode and turn on Secure-Boot!  ║
╚═══════════════════════════════════════════════════════════════════════════════════╝'
printColor "$OUTPUT" "CYAN"

printColor "Press any key to reboot and continue..." CYAN
read -r IGNORE
systemctl reboot --firmware-setup
