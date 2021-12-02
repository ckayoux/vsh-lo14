#!/bin/bash
USAGE="USAGE : `basename $0` {toFS|toArchive <root-dir>} <path>"

toArchive () {
    echo "${*:2:`expr $# - 1`}"'\' |sed "s/\./$1/" |tr '/' '\\' 2> /dev/null
}

toFS () {
    echo "$*" |sed -e 's/[^\\]\+\\/\.\\/' |tr '\\' '/' 2> /dev/null
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

    'toArchive' ) 
    if test $# -ne 3
    then
        echo $USAGE
    else
        shift
        toArchive $*
    fi ;;

    *) echo $USAGE
esac