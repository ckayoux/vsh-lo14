#!/bin/bash
FSUTILS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

GETDIRS="${FSUTILS_DIR}/getdirs.sh"

USAGE="USAGE : `basename "$0"` <archive-path>"
if test $# -ne 1
then
    echo "$USAGE"
    exit -1
fi

ARCHIVE="$1"

ROOTDIR=""
while read -r directory
do
    if test "${#directory}" -lt "${#ROOTDIR}" -o -z "$ROOTDIR"
    then
        ROOTDIR="$directory"
    fi
done < <("$GETDIRS" "$ARCHIVE")
echo "$ROOTDIR"