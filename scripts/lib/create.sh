#!/bin/bash
LIB_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PATHPARSER="${LIB_DIR}/parsepath.sh"
ARCHIVES_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/../archives" &> /dev/null && pwd )"

USAGE="Usage : `basename $0` [archive-path]"

if test $# -gt 1
then
    echo "$USAGE"
    exit -1
fi
if test $# -eq 0
then
    set "${ARCHIVES_DIR}/.created_archive"
fi
ARCHIVE="$1"
HEADERLEN=`expr "$(find . |wc -l)" + 2 \* "$(find -type d |wc -l)" - 2`
HEADERSTART=3
BODYSTART=`expr "$HEADERLEN" + "$HEADERSTART" + 1`
exec > "$ARCHIVE" #les echo écriront dans le fichier $ARCHIVE
echo "$HEADERSTART:$BODYSTART"
for (( i = 2; i < $HEADERSTART ; i++ ))
do
    echo ""
done
R=`basename "$(pwd)"` #racine de l'archive
dirsList=`find . -type d` &> /dev/null #récupération des répertoires
i=0
for d in $dirsList
do
    directory="$("$PATHPARSER" toArchive "$R" "$d")" &> /dev/null
    echo "directory $directory" #début du dossier
    while IFS= read -r f
    do  
        IFS=' '
        #récupération des droits, de la taille et du nom de chaque élément directement contenu dans le dossier
        
        read frights fsize <<< "$(echo $f |cut -d" " -f1,5)"
        fname=`echo "$f" |awk '{ s = ""; for (i = 9; i <= NF; i++) s = s $i " "; print s }'`
        echo "$fname $frights $fsize"
    done <<<  "$(ls -l $d |tail +2)"
    (( i++ ))
    if test $i -lt $HEADERLEN; then echo "@" #fin du dossier
    fi
done
fpos=$HEADERSTART
fcontentstart=$BODYSTART
cd "$(pwd)"
while IFS= read -r line
do
    if [ -n "$(echo "$line" |egrep -- "\-[rwx\-]{9} [0-9]+\$")" ]
    then
        fname=`echo "$line"|awk '{ s = "" ; for (i = 1; i <= NF - 2; i++) s = s $i " "; print s}'`
        exec >> "$ARCHIVE"
        fcontent=""
        while read -r line
        do
            fcontent="$fcontent""$line"
        done < "$("$PATHPARSER" toFS "$d""$fname")"
        echo "$d""$fname" > "/home/f/Bureau/createlog"
        if test -z "$fcontent"
        then
            fcontentlen=0
        else
            fcontentlen=`echo "$fcontent" |wc -l`
            echo "$fcontent" #adding file content to the archive
        fi
        sed -i "${fpos}"'s/\(^.*\)$/\1 '"$fcontentstart $fcontentlen"'/' "$ARCHIVE" #adding file content start and length indexes in the header line
        (( fcontentstart+=fcontentlen ))
    elif [ -n "$(echo $line |egrep "directory (.*)$")" ]
    then
        d=`echo "$line" |sed "s/directory \(.*\)$/\1/"`
    fi
    (( fpos++ ))
done <<< $HEADER
