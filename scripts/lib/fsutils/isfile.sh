#!/bin/bash
FSUTILS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

GETFILES="${FSUTILS_DIR}/getfiles.sh"

USAGE="USAGE : `basename "$0"` <abs-path> <archive>"
if test $# -ne 2
then
    echo "$USAGE"
    exit -1
fi

regexpFriendlyFiles="$(cat < <("$GETFILES" "$2") |awk '{gsub(/\\/,"/");print}')"
regexpFriendlyPath="$(echo "$1" |awk '{gsub(/\\/,"/");print}')"

matches="$(echo "$regexpFriendlyFiles" |grep "$regexpFriendlyPath/\?\$")"

if test -z "$matches"
then
    exit -1
else
    exit 0
fi