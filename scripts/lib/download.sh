#!/bin/bash
USAGE="Usage : `basename $0` <lines-count> <output-path>"
if test $# -ne 2
then
    echo "$USAGE"
    exit -1
fi
output_path=$1
linescount=$2
downloaded=0
> "$output_path"
while read -r line
do
    printf "%s\n" "$line" >> "$output_path"
	((downloaded++))
	if test $downloaded -ge $linescount
	then
		exit 0
	fi
done
exit -1
#if [[ -e "$output_path" && $downloaded -eq `cat "$output_path" |wc -l` ]]
#then
#	exit 0
#else
#	return -1
#fi