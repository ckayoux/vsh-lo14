#!/bin/bash
LIB_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
GETROOTDIR="$LIB_DIR/fsutils/getrootdir.sh"

LOGGER="${LIB_DIR}/logger.sh"
PATHPARSER="${LIB_DIR}/fsutils/parsepath.sh"

ARCHIVESEXT="sos"

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
ARCHIVENAME=`basename "$ARCHIVE" ".$ARCHIVESEXT"`


USAGE="USAGE : `basename "$0"` <archive-path>"
if test $# -ne 1
then
    echo "$USAGE"
    exit -1
fi

if test -w "$(pwd)" #can we write in the current WD ?
then
    echo -n
else
    "$LOGGER" error "Cannot write at '$(pwd)' : permission not granted"
    echo "Try running as root."
    exit -1
fi

firstline=`sed -n 1p "$ARCHIVE"`
HEADERSTART=`echo "$firstline" |cut -d":" -f1`
HEADEREND=`echo "$firstline" |cut -d":" -f2`
HEADERLEN=$(($HEADEREND -$HEADERSTART))
while read -r headerline
do
    if test -n "$(echo "$headerline" |grep "^directory\( \)\+\\.*")"
    then
        #\dir\path -> ./dir/path/
        dir="$( echo "$headerline" |cut -d' ' -f2- |tr '\\' '/' |sed -e "s/\(^.*$\)/\.\1/" )" 
        if test ${dir:`expr ${#dir} - 1`} != '/'
        then
            dir="$dir"'/'
        fi
        mkdir -p "$dir"
    elif test "$headerline" != "@"
    then
        if test -n "$( echo "$headerline" |grep -o '^.* \+*[aDPSLP\-][rwx\-]\{9\}\( [0-9]\+\)\{3\}' )"
        then
            #is not a directory
            read -r rights fstart flen <<< "$(echo "$headerline" |awk '{print $(NF-3) " " $(NF-1) " " $NF;}' |cut -c2-)"
            name="$(echo "$headerline" |awk 'BEGIN{IFS=" "}{ for(i=1;i<NF-4; i++) printf "%s ",$i; print $(NF-4)}')"
            path="$dir$name"
            tail +`expr "$fstart"` "$ARCHIVE" |head -`expr "$flen"` > "$path"
        else
            #is a directory
            read -r rights <<< "$(echo "$headerline" |awk '{print $(NF-1);}' |cut -c2-)"
            name="$(echo "$headerline" |awk 'BEGIN{IFS=" "}{ for(i=1;i<NF-2; i++) printf "%s ",$i; print $(NF-2)}')"
            path="$dir$name"
            mkdir -p "$path"
        fi
        #attribute rights
        read -r u g o <<< "$(echo "${rights:0:3} ${rights:3:3} ${rights:6:3}" )"
        chmod u=$u,g=$g,o=$o "$path"
    fi
done < <(tail +$HEADERSTART "$ARCHIVE" |head -$HEADERLEN)