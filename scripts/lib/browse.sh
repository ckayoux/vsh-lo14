#!/bin/bash
LIB_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
GETROOTDIR="$LIB_DIR/fsutils/getrootdir.sh"

LOGGER="${LIB_DIR}/logger.sh"

ARCHIVE="$1"
if test -e "$ARCHIVE"
then
    if test -f "$ARCHIVE"
    then
        if test -r "$ARCHIVE"
        then
            echo -n
        else
            "$LOGGER" error "Cannot read from archive file '$ARCHIVE'"
            exit -1
        fi
    else
        "$LOGGER" error "'$ARCHIVE' is not a file"
        exit -1
    fi
else
    "$LOGGER" error "Archive '$ARCHIVE' doesn't exist"
    exit -1
fi
ARCHIVENAME=`basename "$ARCHIVE"`


SUBCOMMANDSDIR="$LIB_DIR/browse-commands"
myPWD="$SUBCOMMANDSDIR/pwd.sh"
myCD="$SUBCOMMANDSDIR/cd.sh"
myCAT="$SUBCOMMANDSDIR/cat.sh"
myLS="$SUBCOMMANDSDIR/ls.sh"
myTOUCH="$SUBCOMMANDSDIR/touch.sh"
myMKDIR="$SUBCOMMANDSDIR/mkdir.sh"

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


my-ls () {
    "$myLS" "$ARCHIVE" "$*"
}

my-cat () { 
    "$myCAT" "$ARCHIVE" `echo "$*"`
}

my-touch () { 
    "$myTOUCH" "$ARCHIVE" `echo "$*"`
}

my-mkdir () { 
    "$myMKDIR" "$ARCHIVE" `echo "$*"`
}

echo "Browsing '$ARCHIVENAME'"
dhl
echo
echo "Type 'stop' to disconnect."
echo -ne '\n'"$SHELLSYMBOL"' '
while read -r cmd args
do
    if [[ "$cmd" = 'stop' || "$cmd" = 'dc' || "$cmd" = 'exit' || "$cmd" = 'disconnect' ]]
    then
        break
    elif test -z "$cmd"
    then
        echo -ne '\n'"$SHELLSYMBOL"' '
        continue
    elif test "$(type -t "my-${cmd}")"=='function' -a -n "$(type -t "my-${cmd}")"
    then
        my-"$cmd" "$args"
    else
        "$LOGGER" error "Invalid command '${cmd}'. Use 'help' to list the available commands in this mode."
    fi
    echo -ne '\n'"$SHELLSYMBOL"' '
done
