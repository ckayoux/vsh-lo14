#!/bin/bash
USAGE="USAGE : `basename "$0"` <archive-path>"

if test $# -ne 1
then
    echo "$USAGE"
    exit -1
fi

ARCHIVE="$1"
firstline=`sed -n 1p "$ARCHIVE"`
HEADERSTART=`echo "$firstline" |cut -d":" -f1`
HEADERLEN=$((`echo "$firstline" |cut -d":" -f2` -$HEADERSTART))

while read -r headerline
do
    if test -n "$(echo "$headerline" |awk '{gsub(/\\/,"/");print}' |grep '^directory \(/[^/]\+\)*/$')"
    then
       d=`echo "$headerline" |sed 's/directory //'`
       continue
    fi
    elt="$(echo "$headerline" |grep ".* -[rwx\-]\{9\} [0-9]\+ [0-9]\+ [0-9]\+" |awk '{for(i=1;i<NF-4; i++) printf "%s ",$i;printf "%s\n",$i}')"
    if test -n "$elt"
    then
        echo "$d$elt"
    fi
done < <(tail +$HEADERSTART "$ARCHIVE" |head -$HEADERLEN)