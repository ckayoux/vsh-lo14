#!/bin/bash
USAGE="USAGE : `basename "$0"` <archive-path> <abs-path>"
ARCHIVE="$1"
shift
if test $# -ne 1
then
    echo "$USAGE"
    exit -1
fi

firstline=`sed -n 1p "$ARCHIVE"`
HEADERSTART=`echo "$firstline" |cut -d":" -f1`
HEADERLEN=$((`echo "$firstline" |cut -d":" -f2` -$HEADERSTART))
path="$(echo "$1" |sed 's/\(.*[^\\]\)$/\1\\/')" #adding a backslash at the end if missing
d=""
while read -r headerline
do
    if [ "$headerline" = "directory $path" ]
    then
		d="found"
		continue
	fi

	if [ "$headerline" = '@' ]
	then
		if test -n "$d"
		then break #raw content <name> <rights> <size> [start] [end]
		fi
	else
		if test -n "$d"
		then echo "$headerline" #raw content <name> <rights> <size> [start] [end]
		fi
    fi   

done < <(tail +$HEADERSTART "$ARCHIVE" |head -$HEADERLEN)