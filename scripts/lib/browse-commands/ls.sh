#!/bin/bash
#définir path
#si fichier : afficher le fichier si il existe
#si dossier : afficher le contenu du dossier (hors cachés). etoile si exec, \ si dossier.
#si -l : afficher les droits et la taille
#echo "toto tata titi" |awk '{for (i=NF; i>1; i--) printf "%s ",$i; print $1}' titi tata toto pour écrire à l'envers


LIB_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/../" &> /dev/null && pwd )"

myCD="${LIB_DIR}/browse-commands/cd.sh"
myPWD="${LIB_DIR}/browse-commands/pwd.sh"

GETCONTENT="${LIB_DIR}/fsutils/getcontent.sh"
ISFILE="${LIB_DIR}/fsutils/isfile.sh"

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
USAGE="USAGE : `basename "$0"` [path] [-option...]"


VALIDOPTIONS="lan"
ARGS="$(echo "$*" |awk '{for(i=1;i<=NF;i++) if(sprintf(" %s ",$i) !~ /^ -[a-zA-Z]* $/) printf "%s ",$i; }')" #eliminate options
OPTS=`echo $(echo "$*" |awk '{for(i=1;i<=NF;i++) if(sprintf(" %s ",$i) ~ /^ -[a-zA-Z]* $/) printf "%s ",$i; }' |sed 's/-//')`
l=0
a=0
n=0

i=0

for ((i=0;i<"${#OPTS}"; i++))
do
    opt="${OPTS:`expr $i`:1}"
    case "$opt" in
        l) l=1 ;;
        a) a=1 ;;
        n) n=1 ;;
        *) "$LOGGER" error "Invalid option '$opt' : only {$(echo "$VALIDOPTIONS" |awk '{s=split($0,tab,"");for(i=1;i<s;i++) printf "%s, ",tab[i]; print tab[s];}')} allowed." ;;
    esac
done

if test "$(echo $ARGS |awk 'BEGIN{IFS=" "} {print NF}')" -gt 1
then
    echo "$USAGE"
    exit -1
fi

set "$ARGS"


get-elt-name (){
    #$* has format '<name> <rights> <size>'
    read -r rights size <<< "$(echo "$*" |awk 'BEGIN{IFS=" "}{ for(i=NF-1; i<=NF; i++) printf "%s ",$i;}')"
    rights="$rights\t"
    size="$size\t"
    name="$(echo "$*" |awk 'BEGIN{IFS=" "}{ for(i=1;i<=NF-3; i++) printf "%s ",$i; lastpart=NF-2 ;print $lastpart}')"
    if test $l -eq 0 
    then
        if [ `echo "$rights" |cut -c1` = 'd' ] #it is a directory
        then
            name="$name\\"
        elif [ `echo "$rights" |cut -c4,7,10` = 'xxx' ] #it is an executable
        then
            name="$name*"
        fi
    fi
    echo "$name"
}

must-hide () {
    if [[ "${name:0:1}" = '.' && $a -ne 1 ]]
    then
        return 1
    else
        return 0
    fi    
}

show-elt () {
    #$* has format '<name> <rights> <size>'
    #returns the length of the printed string
    name=`get-elt-name "$*"`
    must-hide "$name"
    if test $? -eq 0
    then
        read -r rights size <<< "$(echo "$*" |awk 'BEGIN{IFS=" "}{ for(i=NF-1; i<=NF; i++) printf "%s ",$i;}')"
        rights="$rights\t"
        size="$size\t"
        if test $l -ne 1
        then
            echo -n "$name"
            return "${#name}"
        else 
            echo -e "$rights $size $name\n"
        fi

    else
        return 0
    fi
}
if test "${#ARGS}" -eq 0
then
    path="$WD"
else
    read -r path <<< "$*"
    path="$("$myCD" "$ARCHIVE" "$path")"
fi
if test $? -ne 0
then
    errmsg="$path"
    read -r path <<< "$*"
    if [ "${path:0:1}" != '\' ] #path is relative
    then
        path="$WD$path" #converting to absolute path
    else
        if [ "$(echo "${path:0:`expr "${#ROOTDIR}"`}" |sed 's/\\$//')" != "$(echo $ROOTDIR |sed 's/\\$//')" ]
        then
            path="$ROOTDIR${path:1}"
        fi
    fi

    "$ISFILE" "$path" "$ARCHIVE"  #is it a file ?
    if test $? -eq 0 
    then
        filename="$(echo "$path" |awk -F'\' '{print $(NF)}')"
        if test $l -eq 0
        then
            echo "$filename" #just echo filename
            exit 0
        else
            a=0
            containedin="$(echo "$path" |sed 's/\(\\\([^\\]\+\\\)*\)\([^\\]*\)/\1/')"
            fileinfo="$("$GETCONTENT" "$ARCHIVE" "$containedin" |grep -o "^$filename"' *[daDPSLP\-][rwx\-]\{9\} [0-9]\+')" #
            echo "$fileinfo"
            exit 0
        fi
    else
        "$LOGGER" error "$errmsg"
        exit -1
    fi
fi

maxstrlen=0
while read -r contentline
do
    str="$(get-elt-name "$contentline")"
    if test "${#str}" -gt $maxstrlen
    then
        maxstrlen="${#str}"
    fi
done < <("$GETCONTENT" "$ARCHIVE" "$path" |grep -o '.* [daDPSLP\-][rwx\-]\{9\} [0-9]\+')
linelen=0
linescount=0
eltscount=0
space="   "

if test $l -eq 1 -a $n -eq 0
then
    echo
    echo "Content of '`"$myPWD"`' :"
    echo "----------------------------------------"
fi

while read -r contentline
do
    str="$(show-elt "$contentline")"
    len=$?
    if test -n "$str"
    then
        if test $l -ne 1
        then
            if test `expr \( "$linelen" + "$len" + "${#space}" \) / 80` -gt $linescount
            then
                echo
                ((linescount++))
            fi
            echo -en "$str"
            ((eltscount++))
            ((linelen+=len))

            len=`expr "${#space}" + "$maxstrlen" - "${#str}" `
            if test `expr \( "$linelen" + "$len" \) / 80` -gt $linescount
            then
                echo
                ((linescount++))
            else
                printf %"$len"s%s "$space"
                ((linelen+=len))
            fi
        else
            ((linescount++))
            echo "$str"
            ((eltscount++))
        fi
    fi
done < <("$GETCONTENT" "$ARCHIVE" "$path" |grep -o '.* [daDPSLP\-][rwx\-]\{9\} [0-9]\+')

if test $l -eq 1 -a $eltscount -gt 1 -a $n -eq 0
then
    echo "----------------------------------------"
    echo "Total : $eltscount elements"
elif test $l -eq 0 -a $eltscount -gt 0
then 
    echo
fi