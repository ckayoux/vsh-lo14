#!/bin/bash

LIB_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/../" &> /dev/null && pwd )"

GETDIRS="${LIB_DIR}/fsutils/getdirs.sh"
FEXISTS="${LIB_DIR}/fsutils/fexists.sh"
ISDIR="${LIB_DIR}/fsutils/isdir.sh"
GETCONTENT="${LIB_DIR}/fsutils/getcontent.sh"

LOGGER="${LIB_DIR}/logger.sh"

DEFAULTRIGHTS="drwxr-xr-x"

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

VALIDOPTIONS="p"
ARGS="$(echo "$*" |awk '{for(i=1;i<=NF;i++) if(sprintf(" %s ",$i) !~ /^ -[a-zA-Z]* $/) printf "%s ",$i; }')" #eliminate options
OPTS=`echo $(echo "$*" |awk '{for(i=1;i<=NF;i++) if(sprintf(" %s ",$i) ~ /^ -[a-zA-Z]* $/) printf "%s ",$i; }' |sed 's/-//')`
p=0

i=0

for ((i=0;i<"${#OPTS}"; i++))
do
    opt="${OPTS:`expr $i`:1}"
    case "$opt" in
        p) p=1 ;;
        *) "$LOGGER" error "Invalid option '$opt' : only {$(echo "$VALIDOPTIONS" |awk '{s=split($0,tab,"");for(i=1;i<s;i++) printf "%s, ",tab[i]; print tab[s];}')} allowed." ;;
    esac
done

if test "$(echo $ARGS |awk 'BEGIN{IFS=" "} {print NF}')" -eq 0
then
    echo "$USAGE"
    exit -1
fi

set `echo "$ARGS"`

while [ $# -gt 0 ]
do
    read -r path <<< "$1"
    if test "$p" -eq 1
    then
        while read -r parentdir
        do
            dblbcklsh="$(echo "$parentdir" |sed 's/\\/\\\\/g')"
            if test -z "$("$GETDIRS" "$ARCHIVE" |grep "$dblbcklsh")"
            then
                "$0" "$ARCHIVE" "$parentdir"
                if test $? -ne 0
                then
                    exit -1
                fi
            fi
        done < <(echo "$path" |awk -F'\' '{for(i=1;i<=NF;i++) { for(j=1;j<=i;j++) printf "%s\\",$j; print ""}}')
    else
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
        "$FEXISTS" "$(echo "$path" |sed 's/\\$//')" "$ARCHIVE"
        if test $? -eq 0 #does the file exist ?
        then
            "$LOGGER" error "$(echo "$path" |sed 's/\\$//') already exists"
            exit -1
        else
            dirname="$(echo "$path" |sed 's/\\$//' |awk -F'\' '{print $(NF)}')"
            containedin="$(echo "$path" |sed 's/\(\\\([^\\]\+\\\)*\)\([^\\]\+\)\\*/\1/')"
            "$FEXISTS" "$(echo "$containedin" |sed 's/\\$//')" "$ARCHIVE"
            if test $? -ne 0 #does the parent folder exist ?
            then
                "$LOGGER" error "'$containedin' doesn't exist."
                exit -1
            else
                "$ISDIR" "$(echo "$containedin" |sed 's/\\$//')" "$ARCHIVE"
                if test $? -ne 0 #is not a directory
                then
                    "$LOGGER" error "'$containedin' is not a directory"
                    exit -1
                else
                    firstline=`sed -n 1p "$ARCHIVE"`
                    HEADERSTART=`echo "$firstline" |cut -d":" -f1`
                    HEADEREND=`echo "$firstline" |cut -d":" -f2`
                    HEADERLEN=$(($HEADEREND -$HEADERSTART))

                    #ARCHIVELEN="$(wc -l < "$ARCHIVE")"
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
                                if [ "${path:`expr "${#path}" - 1`:1}" != '\' ]
                                then
                                    path="$path\\"
                                fi
                                sed -i "`expr $i + $HEADERSTART - 1`"'s/\(.*\)/\1\n'"$dirname $DEFAULTRIGHTS 4096"'\n@\ndirectory '"$(echo "${path}" |sed 's/\\/\\\\/g')"'/' "$ARCHIVE"
                                sed -i '1s/.*/'"$HEADERSTART:`expr $HEADERLEN + $HEADERSTART + 3`"'/' "$ARCHIVE"
                                echo "'$dirname' has been created successfully in '$containedin'."
                                ((HEADERLEN+=3))
                                ((HEADEREND+=3))
                                break
                            fi
                        fi
                    done < <(tail +$HEADERSTART "$ARCHIVE" |head -$HEADERLEN)
                    awkcommand='( NR>='$HEADERSTART' && NR<='$HEADEREND' && ($0 ~ /^.* +[^d][rwx\-]{9} [0-9]+ [0-9]+ [0-9]+/) ) {for (i=1;i<=NF-2; i++) {if(i!=NF-4) printf "%s ",$i; else printf "%s  ",$i};newstart=$(NF-1)+3;printf ("%d %s\n",newstart,$NF);}
                                ( NR>='$HEADERSTART' && NR<='$HEADEREND' && ($0 !~ /^.* +[^d][rwx\-]{9} [0-9]+ [0-9]+ [0-9]+/) ) {print}
                                ( ! (NR>='$HEADERSTART' && NR<='$HEADEREND') ) {print}'
                    echo "$(awk -F' ' "$awkcommand" "$ARCHIVE")" > "$ARCHIVE" #adding 3 to each file's line start
                fi
            fi
        fi
    fi
    shift
done