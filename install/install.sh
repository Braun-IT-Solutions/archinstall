#!/usr/bin/bash

set -e

function print_logo() {
    echo -e ' $$$$$$$\  $$$$$$\ $$$$$$$$\  $$$$$$\' "\n" \
        '$$  __$$\ \_$$  _|\__$$  __|$$  __$$\' "\n" \
        '$$ |  $$ |  $$ |     $$ |   $$ /  \__|' "\n" \
        '$$$$$$$\ |  $$ |     $$ |   \$$$$$$\' "\n" \
        '$$  __$$\   $$ |     $$ |    \____$$\' "\n" \
        '$$ |  $$ |  $$ |     $$ |   $$\   $$ |' "\n" \
        '$$$$$$$  |$$$$$$\    $$ |   \$$$$$$  |' "\n" \
        '\_______/ \______|   \__|    \______/'
    echo -e "\nWelcome to BITS archinstall\n"
}

function ask_user_for_details() {
    echo "Please enter some basic info:" > /dev/tty
    read -p "Your first name (all lowercase): " FIRST_NAME
    read -p "Your last name (all lowercase): " LAST_NAME
    read -p "Your lucky number (just choose one): " LUCKY_NUMBER

    echo "$FIRST_NAME $LAST_NAME $LUCKY_NUMBER"
}

print_logo

IFS=' '
USER_DETAILS=($(ask_user_for_details))
FIRST_NAME=${USER_DETAILS[0]}
LAST_NAME=${USER_DETAILS[1]}
LUCKY_NUMBER=${USER_DETAILS[2]}

LOGIN_NAME="$FIRST_NAME.$LAST_NAME"
echo "Login name: $LOGIN_NAME"

INITIALS="${FIRST_NAME:0:1}${LAST_NAME:0:1}"
HOSTNAME="AXD-${INITIALS^^}${LUCKY_NUMBER}"
echo "Hostname: ${HOSTNAME}"

#./partition.sh

./configuration.sh $LOGIN_NAME $HOSTNAME
