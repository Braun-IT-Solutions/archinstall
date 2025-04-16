SCRIPT_PATH=$(dirname "$0")
cd $SCRIPT_PATH
source ./util.sh

OUTPUT='╔═══════════════════════════════════════════════════════════════════════════════════╗
║ Rebooting, please set Secure-Boot in BIOS to setup mode! And tsurn on Secure-Boot ║
╚═══════════════════════════════════════════════════════════════════════════════════╝'
printColor "$OUTPUT" "CYAN"




