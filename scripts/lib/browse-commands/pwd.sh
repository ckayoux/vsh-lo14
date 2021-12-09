#!/bin/bash
USAGE="USAGE : `basename "$0"`"

if test $# -ne 0
then
    echo "$USAGE"
    exit -1
fi

if test "$WD"!=''
then
    if test "$ROOTDIR"!=''
    then
        sedFriendlyROOTDIR="$(echo "${ROOTDIR}" |awk '{gsub(/\\/,"\\\\");print}')" 
        echo "$WD" |sed 's/'"${sedFriendlyROOTDIR}"'/\\/'
    fi
fi