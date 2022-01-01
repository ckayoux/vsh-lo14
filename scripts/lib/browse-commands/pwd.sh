#!/bin/bash
USAGE="USAGE : `basename "$0"`"

if test $# -ne 0
then
    echo "$USAGE"
    exit -1
fi

if test "$WD"!=''
then
    echo "${WD:`expr "${#ROOTDIR}" - 1`}"
fi