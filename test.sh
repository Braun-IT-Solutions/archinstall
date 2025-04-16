SCRIPT_PATH=$(dirname "$0")
cd $SCRIPT_PATH
source ./util.sh

OUTPUT="\
    ╔═══════════════════════════════╗\n\
    ║ Please enter some basic info: ║\n\
    ╚═══════════════════════════════╝\n"
    echo -e $(printColor "$OUTPUT" "RED")
    OUTPUT="Please enter some basic info:\n"
    echo -e $(printColor "$OUTPUT" RED)


    OUTPUT="Your first name (all lowercase):"
    echo -e $(printColor "$OUTPUT" "RED")
    read -p "" FIRST_NAME

    OUTPUT="Your last name (all lowercase):"
    echo -e $(printColor "$OUTPUT" "RED")
    read -p "" LAST_NAME

    OUTPUT="Your lucky number (just choose one):"
    echo -e $(printColor "$OUTPUT" "RED")
    read -p "" LUCKY_NUMBER


    if ! [ -n "$FIRST_NAME" ] && [ " " != "$FIRST_NAME" ] && ! [ -n "$LAST_NAME" ] && [ " " != "$LAST_NAME" ] 2>/dev/null; then
OUTPUT="\
╔═══════════════════════════════════╗\n\
║ Error with parameters, exiting... ║\n\
╚═══════════════════════════════════╝\n"
echo -e $(printColor "$OUTPUT" RED)
sleep 5
exit 1
    fi

