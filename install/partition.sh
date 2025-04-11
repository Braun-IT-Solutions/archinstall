
function disks_with_name_and_size() {
    AVAILABLE_DISKS=$(lsblk -r | cut -d' ' -f1,4)
    IFS=$'\n'
    AVAILABLE_DISKS=($AVAILABLE_DISKS)
    AVAILABLE_DISKS=("${AVAILABLE_DISKS[@]:1}")
    printf '%s\n' "${AVAILABLE_DISKS[@]}"
}

function ask_user_for_disk() {
    while true; do
        IFS=$'\n'
        DISKS=($(disks_with_name_and_size))

        echo "Please select the drive to install Linux to:" > /dev/tty
        for i in "${!DISKS[@]}"; do
            LINE=${DISKS[$i]}
            IFS=' '
            LINE=(${LINE[@]})
            echo "    $i - /dev/${LINE[0]}    Size: ${LINE[1]}" > /dev/tty
            IFS=$'\n'
        done

        read -p "Select a partition: " SELECTED_INDEX

        SELECTED_DISK=${DISKS[$SELECTED_INDEX]}
        if [ -v "DISKS[$SELECTED_INDEX]" ] && [ "$SELECTED_INDEX" -eq "$SELECTED_INDEX" ] 2>/dev/null; then
            IFS=' '
            SELECTED_NAME=(${SELECTED_DISK[0]})
            echo "${SELECTED_NAME[0]}"
            return
        else
            echo "Disk with index $SELECTED_INDEX does not exist, try again" > /dev/tty
            sleep 2
        fi
    done
}

INSTALL_DISK=$(ask_user_for_disk)
echo "INSTALL_DISK=$INSTALL_DISK"
