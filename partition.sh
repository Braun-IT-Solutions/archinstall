#Checks for both parameters
#1: Login-name
#2: Hostname
check_parameters(){
    if ! [ -n "$1" ] && [ " " != "$1" ] && ! [ -n "$2" ] && [ " " != "$2" ] 2>/dev/null; then
        OUTPUT="\
        ╔═══════════════════════════════════╗\n\
        ║ Error with parameters, exiting... ║\n\
        ╚═══════════════════════════════════╝\n"
        printColor "$OUTPUT" RED
        sleep 5
        exit 1
    fi
}

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

        OUTPUT="Please select the drive to install Linux to"
        printColor "$OUTPUT" "RED"
        OUTPUT="The Drive is gonna be formatted and existing partitions are wiped"
        printColor "$OUTPUT" "RED"

        for i in "${!DISKS[@]}"; do
            LINE=${DISKS[$i]}
            IFS=' '
            LINE=(${LINE[@]})
            echo "    $i - /dev/${LINE[0]}    Size: ${LINE[1]}"
            IFS=$'\n'
        done

        OUTPUT="Select a partition:"
        printColor "$OUTPUT" GREEN
        read -p "" SELECTED_INDEX

        SELECTED_DISK=${DISKS["$SELECTED_INDEX"]}
        if [ -v "DISKS[$SELECTED_INDEX]" ] && [ "$SELECTED_INDEX" -eq "$SELECTED_INDEX" ] 2>/dev/null; then
            IFS=' '
            SELECTED_NAME=(${SELECTED_DISK[0]})
            echo "/dev/${SELECTED_NAME[0]}"
            return
        else
            OUTPUT="Disk with index $SELECTED_INDEX does not exist, try again"
            printColor "$OUTPUT" "RED"
            sleep 2
        fi
    done
}

#Wipes handed device of partitions and creates new ones according to "./partition-scheme.sfdisk"
function partition_disk() {

    OUTPUT="Wiping Partitions off of disk ${1}..."
    printColor "$OUTPUT" GREEN
    #Wipes all Partitions off the device
    wipefs -a $1

    OUTPUT="Partitioning disk ${1}..."
    printColor "$OUTPUT" GREEN
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
    OUTPUT="Formatting partitions..."
    printColor "$OUTPUT" GREEN

    EFI_PARTITION=$1
    ROOT_PARTITION=$2

    OUTPUT="Formatting /efi..."
    printColor "$OUTPUT" GREEN
    #creates MS-DOS FAT Filesystem
    mkfs.vfat -F32 $EFI_PARTITION

    OUTPUT="Creating LUKS partition..."
    printColor "$OUTPUT" GREEN
    # Initialize a LUKS partition and,
    #set the initial passphrase from "./luks-temp.key"
    cryptsetup luksFormat --type luks2 -q $ROOT_PARTITION luks-temp.key
    #Creates a mapping with "linuxroot" in device "$ROOT_PARTITION",
    #needs the temporary password in "./luks-temp.key"
    cryptsetup luksOpen $ROOT_PARTITION linuxroot --key-file=luks-temp.key

    OUTPUT="Formatting /..."
    printColor "$OUTPUT" GREEN
    #creates ext4 Filesystem
    mkfs.ext4 "/dev/mapper/linuxroot"
}

#Mounts EFI and ROOT Partition
function mount_filesystem() {

    OUTPUT="Mounting ${1} to /mnt/efi..."
    printColor "$OUTPUT" GREEN
    #EFI
    mount --mkdir $1 /mnt/efi

    OUTPUT="Mounting /dev/mapper/linuxroot to /mnt..."
    printColor "$OUTPUT" GREEN
    #ROOT
    mount /dev/mapper/linuxroot /mnt
}

#Catches errors and stops the script early
set -eo pipefail

SCRIPT_PATH=$(dirname "$0")
cd $SCRIPT_PATH
source ./util.sh

INSTALL_DISK=$(ask_user_for_disk)
OUTPUT="${INSTALL_DISK}"
printColor "$OUTPUT" GREEN

if ! [ -n "$INSTALL_DISK" ] && [ " " != "$INSTALL_DISK" ] 2>/dev/null; then
        OUTPUT="\
        ╔═══════════════════════════════════╗\n\
        ║ Error with parameters, exiting... ║\n\
        ╚═══════════════════════════════════╝\n"
        printColor "$OUTPUT" RED
        sleep 5
        exit 1
fi
 
partition_disk $INSTALL_DISK

IFS=$'\n'
PARTITIONS=($(get_partitions $INSTALL_DISK))
echo "Partitions: ${PARTITIONS[@]}"

check_parameters ${PARTITIONS[@]}

#PARTITIONS[0] = EFI
#PARTITIONS[1] = ROOT
format_disk ${PARTITIONS[@]}

mount_filesystem ${PARTITIONS[0]}
