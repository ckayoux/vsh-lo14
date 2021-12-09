#!/bin/bash
LIB_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

GETDIRS="${LIB_DIR}/../fsutils/getdirs.sh"
FEXISTS="${LIB_DIR}/../fsutils/fexists.sh"
ISDIR="${LIB_DIR}/../fsutils/isdir.sh"

LOGGER="${LIB_DIR}/../logger.sh"

USAGE="USAGE : `basename "$0"` <archive> [path]"

if test $# -gt 2 -o $# -lt 1
then
    echo "$USAGE"
    exit -1
fi

ARCHIVE="$1"
path="$2"

if test "$WD"!=''
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
    else #path is relative or absolute
        if [ "${path:0:1}" != '\' ] #path is relative
        then
            path="$WD$path" #converting to absolute path
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
fi
