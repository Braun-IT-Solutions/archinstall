#!/bin/bash

source util.sh
while true; do
    OUTPUT="Please enter a new secure password for your user: "
    printColor "$OUTPUT" CYAN
    #use -s to hide typed keys
    read -r -s -p "Password: " NEW_PASSWORD
    echo
    read -r -s -p "Repeat: " REPEAT_PASSWORD
    echo

    if [ "$NEW_PASSWORD" = "$REPEAT_PASSWORD" ]; then
        echo "DONE"
        break
    else
        OUTPUT="Passwords do not match. Please try again."
        printColor "$OUTPUT" RED
    fi
done
