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

tail +$HEADERSTART "$ARCHIVE" |head -$HEADERLEN |grep '^directory \(\\.*\\\)$' | sed 's/^directory \(\\.*\\\)$/\1/'