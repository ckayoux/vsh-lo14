#!/bin/bash

LIB_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/../" &> /dev/null && pwd )"

GETDIRS="${LIB_DIR}/fsutils/getdirs.sh"
FEXISTS="${LIB_DIR}/fsutils/fexists.sh"
ISDIR="${LIB_DIR}/fsutils/isdir.sh"
GETCONTENT="${LIB_DIR}/fsutils/getcontent.sh"

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

shift
USAGE="USAGE : `basename "$0"` [path-to-file...]" 

if test $# -eq 0
then
    echo "$USAGE"
    exit -1
fi

while [ $# -gt 0 ]
do
    read -r path <<< "$1"
    if [ "${path:0:1}" != '\' ] #path is relative
    then
        path="$WD$path" #converting to absolute path
    else
        if [ "$(echo "${path:0:`expr "${#ROOTDIR}"`}" |sed 's/\\$//')" != "$(echo $ROOTDIR |sed 's/\\$//')" ]
        then
            path="$ROOTDIR${path:1}"
        fi
    fi

    "$FEXISTS" "$path" "$ARCHIVE"
    if test $? -eq 0 #does the file exist ?
    then
        "$ISDIR" "$path" "$ARCHIVE" #is it a directory ?
        if test $? -ne 0 
        then
            filename="$(echo "$path" |awk -F'\' '{print $(NF)}')"
            containedin="$(echo "$path" |sed 's/\(\\\([^\\]\+\\\)*\)\([^\\]*\)/\1/')"
            fileinfo="$("$GETCONTENT" "$ARCHIVE" "$containedin" |grep -o "^$filename"' *[daDPSLP\-][rwx\-]\{9\} [0-9]\+ [0-9]\+ [0-9]\+')" #
            read -r filestart filelen < <(echo "$fileinfo" |awk 'BEGIN{IFS=" "}{printf "%s %s\n",$(NF-1),$NF}')
            tail +`expr "$filestart"` "$ARCHIVE" |head -`expr "$filelen"`
        else
            "$LOGGER" error "'$path' is a directory"
        fi
    else
        "$LOGGER" error "'$path' does not exist in `basename $ARCHIVE`"
    fi

    shift
done



