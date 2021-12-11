#!/bin/bash
LIB_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/../" &> /dev/null && pwd )"

GETDIRS="${LIB_DIR}/fsutils/getdirs.sh"
FEXISTS="${LIB_DIR}/fsutils/fexists.sh"
ISDIR="${LIB_DIR}/fsutils/isdir.sh"

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
USAGE="USAGE : `basename "$0"` [path]" 


path="$1"

if test -n "$WD"
then
    if [[ -z "$path" || "$path" = '\' ]] #no args or arg is '\' -> go to root dir
    then
        echo "$ROOTDIR"
    elif [ "$path" = '..' ] #arg is '..' -> go to parent dir
    then
        if [ "$WD" = "$ROOTDIR" ]
        then
            echo "$ROOTDIR"
        else
            echo "$WD" |sed 's/^\(.*\\\)[^\\]\+[\\]\?$/\1/'
        fi
    elif [ "$path" = '.' ]
    then
        echo "$WD"
    else #path is relative or absolute
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
            if test $? -eq 0 
            then
                if [ "${path:`expr ${#path} - 1`:1}" != '\' ] #adding a final \ if there is none at the end of the path
                then
                    path="$path"'\'
                fi
                echo "$path"
            else
                echo "'$path' is not a directory"
                exit -1
            fi
        else
            echo "'$path' does not exist in `basename $ARCHIVE`"
            exit -1
        fi

    fi
else
    exit -1
fi
