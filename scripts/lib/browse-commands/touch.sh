#!/bin/bash

LIB_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/../" &> /dev/null && pwd )"

GETDIRS="${LIB_DIR}/fsutils/getdirs.sh"
FEXISTS="${LIB_DIR}/fsutils/fexists.sh"
ISDIR="${LIB_DIR}/fsutils/isdir.sh"
GETCONTENT="${LIB_DIR}/fsutils/getcontent.sh"

LOGGER="${LIB_DIR}/logger.sh"

DEFAULTRIGHTS="-rwxr-xr-x"


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
    if [ "$path" = '..' ] #arg is '..' -> go to parent dir
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
    fi

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
        "$LOGGER" error "'$path' already exists"
    else
        filename="$(echo "$path" |awk -F'\' '{print $(NF)}')"
        containedin="$(echo "$path" |sed 's/\(\\\([^\\]\+\\\)*\)\([^\\]*\)/\1/')"
        "$FEXISTS" "$(echo "$containedin" |sed 's/\\$//')" "$ARCHIVE"
        if test $? -ne 0 #does the parent folder exist ?
        then
            "$LOGGER" error "'$containedin' doesn't exist"
        else
            "$ISDIR" "$(echo "$containedin" |sed 's/\\$//')" "$ARCHIVE"
            if test $? -ne 0 #is not a directory
            then
                "$LOGGER" error "'$containedin' is not a directory"
            else
                firstline=`sed -n 1p "$ARCHIVE"`
                HEADERSTART=`echo "$firstline" |cut -d":" -f1`
                HEADEREND=`echo "$firstline" |cut -d":" -f2`
                HEADERLEN=$(($HEADEREND - $HEADERSTART))
                ARCHIVELEN="$(wc -l < "$ARCHIVE")"
                i=-1
                while read -r headerline
                do
                    ((i++))
                    if [ "$headerline" = "directory $containedin" ]
                    then
                        d="found"
                        continue
                    fi

                    if [ "$headerline" = '@' ]
                    then
                        if test -n "$d"
                        then  
                            sed -i "`expr $i + $HEADERSTART - 1`"'s/\(.*\)/\1\n'"$filename $DEFAULTRIGHTS 0 $ARCHIVELEN 0"'/' "$ARCHIVE"
                            sed -i '1s/\(.*\)/'"$HEADERSTART:`expr $HEADERLEN + 1 + $HEADERSTART`"'/' "$ARCHIVE"
                            echo "'$filename' has been created successfully in '$containedin'."
                            ((HEADEREND++))
                            ((HEADERLEN++))
                            break
                        fi
                    fi
                done < <(tail +$HEADERSTART "$ARCHIVE" |head -$HEADERLEN)
                awkcommand='( NR>='$HEADERSTART' && NR<='$HEADEREND' && ($0 ~ /^.* +[^d][rwx\-]{9} [0-9]+ [0-9]+ [0-9]+/) ) {for (i=1;i<=NF-2; i++) {if(i!=NF-4) printf "%s ",$i; else printf "%s  ",$i};newstart=$(NF-1)+1;printf ("%d %s\n",newstart,$NF);}
                            ( NR>='$HEADERSTART' && NR<='$HEADEREND' && ($0 !~ /^.* +[^d][rwx\-]{9} [0-9]+ [0-9]+ [0-9]+/) ) {print}
                            ( ! (NR>='$HEADERSTART' && NR<='$HEADEREND') ) {print}'
                echo "$(awk -F' ' "$awkcommand" "$ARCHIVE")" > "$ARCHIVE" #adding 1 to each file's line start
            fi
        fi
    fi
    shift
done



