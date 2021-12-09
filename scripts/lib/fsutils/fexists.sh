#!/bin/bash
FSUTILS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

GETDIRS="${FSUTILS_DIR}/getdirs.sh"
GETFILES="${FSUTILS_DIR}/getfiles.sh"

USAGE="USAGE : `basename "$0"` <abs-path> <archive>"

if test $# -ne 2
then
    echo "$USAGE"
    exit -1
fi
regexpFriendlyDirs="$(cat < <("$GETDIRS" "$2") |awk '{gsub(/\\/,"/");print}')"
regexpFriendlyFiles="$(cat < <("$GETFILES" "$2") |awk '{gsub(/\\/,"/");print}')"
regexpFriendlyPath="$(echo "$1" |awk '{gsub(/\\/,"/");print}')"
matches="$(echo "$regexpFriendlyDirs" |grep "$regexpFriendlyPath/\?\$")$(echo "$regexpFriendlyFiles" |grep "$regexpFriendlyPath/\?\$")"
if test -n "$matches"
then
    exit 0
else
    exit -1
fi