#!/bin/bash
FSUTILS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

GETDIRS="${FSUTILS_DIR}/getdirs.sh"

USAGE="USAGE : `basename "$0"` <abs-path> <archive>"
if test $# -ne 2
then
    echo "$USAGE"
    exit -1
fi

regexpFriendlyDirs="$(cat < <("$GETDIRS" "$2") |awk '{gsub(/\\/,"/");print}')"
regexpFriendlyPath="$(echo "$1" |awk '{gsub(/\\/,"/");print}')"
matches="$(echo "$regexpFriendlyDirs" |grep "$regexpFriendlyPath/\?\$")"

if test -n "$matches"
then
    exit 0
else
    exit -1
fi