#!/bin/bash
LIB_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
GETROOTDIR="$LIB_DIR/fsutils/getrootdir.sh"

ARCHIVE="./toto.sos" ##
ARCHIVENAME=`basename "$ARCHIVE"`

LOGGER="${LIB_DIR}/logger.sh"

SUBCOMMANDSDIR="$LIB_DIR/browse-commands"
myPWD="$SUBCOMMANDSDIR/pwd.sh"
myCD="$SUBCOMMANDSDIR/cd.sh"

SHELLSYMBOL='฿' #阝 #$ #𰻝

export ROOTDIR=`"$GETROOTDIR" "$ARCHIVE"`
export WD="$ROOTDIR"

ddl() {
    echo "------------------------------"
}
dhl() {
    echo "______________________________"
}

my-help () {
    echo
    echo "Available commands in 'Browse' mode :"
    ddl
    echo " + pwd : Prints the current working directory."
    echo " + cd : Change the current directory to the given absolute or relative path."
    echo
    echo "-- Use 'help <command>' to get detailed help about a given command --"
    echo
}

my-pwd () {
    "$myPWD"
}

my-cd () {
    cdResult=`"$myCD" "$ARCHIVE" "$*"`
    if test $? -eq 0
    then
        WD="$cdResult"
    else
        "$LOGGER" error "$cdResult"
    fi
}

echo "Browsing '$ARCHIVENAME'."
dhl
echo -ne '\n'"$SHELLSYMBOL"' '
while read -r cmd args
do
    if test "$(type -t "my-${cmd}")"=='function' -a -n "$(type -t "my-${cmd}")"
    then
        my-"$cmd" "$args"
    else
        "$LOGGER" error "Invalid command '${cmd}'. Use 'help' to list the available commands in this mode."
    fi
    echo -ne '\n'"$SHELLSYMBOL"' '
done
