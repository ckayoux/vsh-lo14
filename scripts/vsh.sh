#!/bin/bash
SCRIPTDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"
LIBDIR="${SCRIPTDIR}lib/"
CHECK_DEPENDENCIES="${LIBDIR}dependencies.sh"
LOGGER="${LIBDIR}logger.sh"
VSH_SERVER="${SCRIPTDIR}vsh-server.sh"
VSH_CLI="${SCRIPTDIR}vsh-cli.sh"

"$CHECK_DEPENDENCIES"
if test $? -ne 0
then exit -1
fi

parse-args () {
	CMD=`echo "$1" |sed 's/-\?\([a-zA-Z]\)/\1/'` #transforms -cmd into cmd if there is a '-' 
	shift
	ARGS="$*"

	case $CMD in
	    '-listen' | 'listen' )
			PORTS=""
			for arg in "$@"
			do
				if test -n "$(echo "$arg" |grep '^[0-9]\+-[0-9]\+$')" #ports range going to be converted into list of individual ports
				then
					rangestart="$(echo $arg |cut -d"-" -f1)"
					rangeend="$(echo $arg |cut -d"-" -f2)"
					p="$rangestart"
					for ((i=$rangestart+1 ; i<=$rangeend ; i++))
					do
						p="$p $i"
					done
				else
					p="$arg"
				fi
				if test -n "$PORTS"
				then
					PORTS="$PORTS $p"
				else
					PORTS="$p"
				fi
			done
			"$VSH_SERVER" "$PORTS";;

		'list' | 'create' | 'browse' | 'extract')
			"$VSH_CLI" $CMD "$ARGS";;
		

	    	*) "$LOGGER" 'unknown-command-error';;
	esac
}

parse-args $@