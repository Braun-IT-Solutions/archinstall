GREEN="\033[32m"
RED="\033[31m"
END="\033[0m"

#Returns all avialable Block devices(hard drives and partitions) with name & size as fields
function disks_with_name_and_size() {
    AVAILABLE_DISKS=$(lsblk -r | cut -d' ' -f1,4)
    IFS=$'\n'
    AVAILABLE_DISKS=($AVAILABLE_DISKS)
    AVAILABLE_DISKS=("${AVAILABLE_DISKS[@]:1}")
    printf '%s\n' "${AVAILABLE_DISKS[@]}"
}

#Prints avialable Block devices and makes you choose one for installation. 
#Returns name of the chosen Block device
function ask_user_for_disk() {
    while true; do
        IFS=$'\n'
        DISKS=($(disks_with_name_and_size))

        echo "Please select the drive to install Linux to:" > /dev/tty
        echo "${RED}The Drive is gonna be formatted and existing partitions are wiped${END}" > /dev/tty
        for i in "${!DISKS[@]}"; do
            LINE=${DISKS[$i]}
            IFS=' '
            LINE=(${LINE[@]})
            echo "    $i - /dev/${LINE[0]}    Size: ${LINE[1]}" > /dev/tty
            IFS=$'\n'
        done

        read -p "Select a partition: " SELECTED_INDEX

        SELECTED_DISK=${DISKS["$SELECTED_INDEX"]}
        if [ -v "DISKS[$SELECTED_INDEX]" ] && [ "$SELECTED_INDEX" -eq "$SELECTED_INDEX" ] 2>/dev/null; then
            IFS=' '
            SELECTED_NAME=(${SELECTED_DISK[0]})
            echo "/dev/${SELECTED_NAME[0]}"
            return
        else
            echo "${RED}Disk with index $SELECTED_INDEX does not exist, try again${END}" > /dev/tty
            sleep 2
        fi
    done
}

#Wipes handed device of partitions and creates new ones according to "./partition-scheme.sfdisk"
function partition_disk() {
    echo "Partitioning disk $1..."
    #Wipes all Partitions off the device
    wipefs -a $1
    #Creates new Partitions according to scheme
    sfdisk $1 < partition-scheme.sfdisk
}

#Returns all existing Partitions from handed device
function get_partitions() {   
    PARTITIONS=$(lsblk -r $1 | cut -d' ' -f1)
    IFS=$'\n'
    PARTITIONS=($PARTITIONS)
    PARTITIONS=("${PARTITIONS[@]:2}")
    printf '%s\n' "${PARTITIONS[@]/#//dev/}"
}

#Formats EFI and ROOT Partition
function format_disk() {
    echo "Formatting partitions..."

    EFI_PARTITION=$1
    ROOT_PARTITION=$2

    echo "Formatting /efi..."
    #creates MS-DOS FAT Filesystem
    mkfs.vfat -F32 $EFI_PARTITION

    echo "Creating LUKS partition"
    # Initialize a LUKS partition and,
    #set the initial passphrase from "./luks-temp.key"
    cryptsetup luksFormat --type luks2 -q $ROOT_PARTITION luks-temp.key
    #Creates a mapping with "linuxroot" in device "$ROOT_PARTITION",
    #needs the temporary password in "./luks-temp.key"
    cryptsetup luksOpen $ROOT_PARTITION linuxroot --key-file=luks-temp.key

    echo "Formatting /"
    #creates ext4 Filesystem
    mkfs.ext4 "/dev/mapper/linuxroot"
}

#Mounts EFI and ROOT Partition
function mount_filesystem() {
    #EFI
    mount --mkdir $1 /mnt/efi
    #ROOT
    mount /dev/mapper/linuxroot /mnt
}

#Catches errors and stops the script early
set -eo pipefail

INSTALL_DISK=$(ask_user_for_disk)
echo $INSTALL_DISK
 
partition_disk $INSTALL_DISK

IFS=$'\n'
PARTITIONS=($(get_partitions $INSTALL_DISK))
echo "Partitions: ${PARTITIONS[@]}"

#PARTITIONS[0] = EFI
#PARTITIONS[1] = ROOT
format_disk ${PARTITIONS[@]}

mount_filesystem ${PARTITIONS[0]}
