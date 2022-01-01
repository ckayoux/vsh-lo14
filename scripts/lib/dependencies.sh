#!/bin/bash
#added because the software didnt work on ubuntu.
LIBDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"

LOGGER="${LIBDIR}logger.sh"
requires=( "gawk" )

missing=0
for dependency in $requires
do
	which "$dependency" &> /dev/null
	if test $? -ne 0
	then
		"$LOGGER" missing "$dependency"
		((missing++))
	fi
done
if test $missing -gt 0
then
	exit -1
fi