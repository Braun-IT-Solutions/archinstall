SCRIPT_PATH=$(dirname "$0")
cd $SCRIPT_PATH
source ./util.sh


temp1="LOGIN_NAME"
temp2="HOST_NAME"
temp3="TEMPORARY PASSWORD"
temp4=$(cat ./luks-temp.key)

OUTPUT='╔════════════════════════════════════════════════════════════════════════════════════════════════╗
║ This is your Login-name, Hostname, your temporary password and hard-drive decryption password. ║
║                           PLEASE WRITE THEM DOWN OR REMEMBER THEM!                             ║
╚════════════════════════════════════════════════════════════════════════════════════════════════╝\n'
    printColor "$OUTPUT" "YELLOW"
   
    LUKS_KEY=$(cat ./luks-temp.key)

    OUTPUT="Login-name: $temp1\nHostname: $temp2\nTemporary user password: $temp3\nTemporary Hard-drive decryption password: $LUKS_KEY\n\n"

    printColor "$OUTPUT" "YELLOW"


OUTPUT='╔═══════════════════════════════════════════════════════════════════════════════════╗
║ Rebooting, please set Secure-Boot in BIOS to setup mode and turn on Secure-Boot!  ║
╚═══════════════════════════════════════════════════════════════════════════════════╝'
    printColor "$OUTPUT" "CYAN"