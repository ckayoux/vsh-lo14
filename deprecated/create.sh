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
OLDIFS=$IFS
ARCHIVE="$1"
HEADER="/tmp/.temp_header"
HEADERLEN=`expr "$(find . |wc -l)" + 2 \* "$(find -type d |wc -l)" - 2`
HEADERSTART=3
BODYSTART=`expr "$HEADERLEN" + "$HEADERSTART" + 1`
exec > "$HEADER" #les echo écriront dans le fichier $ARCHIVE
R=`basename "$(pwd)"` #racine de l'archive
dirsList=`find . -type d` &> /dev/null #récupération des répertoires
i=0
for d in $dirsList
do
    directory="$("$PATHPARSER" toArchive "$R" "$d")" &> /dev/null
    echo "directory $directory" #début du dossier
    while IFS= read -r f
    do  
        if test -z "$f"
        then
            break
        fi

        IFS=' '
        #récupération des droits, de la taille et du nom de chaque élément directement contenu dans le dossier
        read frights fsize <<< "$(echo $f |cut -d" " -f1,5)"
        fname=`echo "$f" |awk '{ s = ""; for (i = 9; i <= NF; i++) s = s $i " "; print s }'`
        echo "$fname $frights $fsize"
    done <<<  "$(ls -al $d |tail +4)"
    (( i++ ))
    if test $i -lt $HEADERLEN; then echo "@" #fin du dossier
    fi
done
exec > "$ARCHIVE"
echo "$HEADERSTART:$BODYSTART"
for (( i = 2; i < $HEADERSTART ; i++ ))
do
    echo ""
done
while IFS= read -r line
do
    printf "%s\n" "$line"
done <"$HEADER"

fpos=$HEADERSTART
fcontentstart=$BODYSTART
cd "$(pwd)"
while IFS= read -r line
do
    printf "$line" >> "/home/f/Bureau/createlog"
    if [ -n "$(echo "$line" |egrep -- "\-[rwx\-]{9} [0-9]+\$")" ]
    then
        fname=`echo "$line"|awk '{ s = "" ; for (i = 1; i <= NF - 2; i++) s = s $i " "; print s}'`
        exec >> "$ARCHIVE"
        fcontent=`cat "$("$PATHPARSER" toFS "$d""$fname")"`
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
done < "$HEADER"
rm "$HEADER"