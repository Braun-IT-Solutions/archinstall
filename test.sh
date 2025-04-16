SCRIPT_PATH=$(dirname "$0")
cd $SCRIPT_PATH
source ./util.sh

OUTPUT="\
    ╔═══════════════════════════════╗\n\
    ║ Please enter some basic info: ║\n\
    ╚═══════════════════════════════╝\n"
    echo -e $(printColor "$OUTPUT" "RED")
    OUTPUT="Please enter some basic info:\n"
    echo -e $(printColor "$OUTPUT" RED) > /dev/tty


