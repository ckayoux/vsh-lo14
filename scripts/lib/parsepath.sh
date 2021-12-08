#!/bin/bash
USAGE="USAGE : `basename $0` {toFS|toArchive} <root-dir> <path>"

toArchive () {
    
    archiveRoot=`echo "$*" |cut -d"|" -f1 |sed "s/'//g"`
    relpath=`echo "$*" |cut -d"|" -f2 |sed "s/'//g"`
    archiveRoot="$(echo "$archiveRoot" |sed 's/\/$//' |awk '{gsub("/","\\/");print}')"
    echo "$relpath"'\' |sed "s/\./$archiveRoot/" |tr '/' '\\' 2> /dev/null
}

toFS () {
    echo "$*" |sed -e 's/[^\\]\+\\\(\([^\\]\+\\\)*\)/\.\\\1/' |tr '\\' '/' 2> /dev/null
}
toAbsFS () {
    echo "$*" |tr '\\' '/' 2> /dev/null
}

case $1 in
    'toFS' ) 
    if test $# -ne 2
    then
        echo $USAGE
    else
        shift
        toFS $*
    fi ;;

    'toAbsFS' ) 
    if test $# -ne 2
    then
        echo $USAGE
    else
        shift
        toAbsFS $*
    fi ;;

    'toArchive' ) 
    if test $# -ne 3
    then
        echo $USAGE
    else
        shift
        toArchive `echo "$1|$2"`
    fi ;;

    *) echo $USAGE
esac