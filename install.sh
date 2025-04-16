#!/usr/bin/bash

#Prints BITS-ASCI logo...
function print_logo() {
    echo -e '\n\n $$$$$$$\  $$$$$$\ $$$$$$$$\  $$$$$$\' "\n" \
        '$$  __$$\ \_$$  _|\__$$  __|$$  __$$\' "\n" \
        '$$ |  $$ |  $$ |     $$ |   $$ /  \__|' "\n" \
        '$$$$$$$\ |  $$ |     $$ |   \$$$$$$\' "\n" \
        '$$  __$$\   $$ |     $$ |    \____$$\' "\n" \
        '$$ |  $$ |  $$ |     $$ |   $$\   $$ |' "\n" \
        '$$$$$$$  |$$$$$$\    $$ |   \$$$$$$  |' "\n" \
        '\_______/ \______|   \__|    \______/'
    echo -e "\nWelcome to BITS archinstall\n"
} 

#Function to ask for user detail. User details are gonna be used to automatically set Login-name and Hostname
function ask_user_for_details() {

    OUTPUT="Your first name (all lowercase):"
    printColor "$OUTPUT" "CYAN"
    read -p "" FIRST_NAME

    OUTPUT="Your last name (all lowercase):"
    printColor "$OUTPUT" "CYAN"
    read -p "" LAST_NAME

    OUTPUT="Your lucky number (just choose one):"
    printColor "$OUTPUT" "CYAN"
    read -p "" LUCKY_NUMBER

    echo "$FIRST_NAME $LAST_NAME $LUCKY_NUMBER"
}

SCRIPT_PATH=$(dirname "$0")
cd $SCRIPT_PATH
source ./util.sh

#Catches errors and stops the script early
set -eo pipefail

print_logo

#Setup for Login-name and Hostname for use in ./configuration
IFS=' '
USER_DETAILS=($(ask_user_for_details))
FIRST_NAME=${USER_DETAILS[0]}
LAST_NAME=${USER_DETAILS[1]}
LUCKY_NUMBER=${USER_DETAILS[2]}

LOGIN_NAME="$FIRST_NAME.$LAST_NAME"
OUTPUT="Login name: $LOGIN_NAME"
printColor "$OUTPUT" GREEN

INITIALS="${FIRST_NAME:0:1}${LAST_NAME:0:1}"
HOSTNAME="AXD-${INITIALS^^}${LUCKY_NUMBER}"
OUTPUT="Hostname: ${HOSTNAME}"
printColor "$OUTPUT" GREEN
sleep 1

./partition.sh

./configuration.sh $LOGIN_NAME $HOSTNAME


