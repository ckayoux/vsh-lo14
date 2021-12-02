#!/bin/bash
SCRIPTDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"
LIBDIR="${SCRIPTDIR}lib/"
LOGGER="${LIBDIR}logger.sh"
VSH_SERVER="${SCRIPTDIR}vsh-server.sh"
VSH_CLI="${SCRIPTDIR}vsh-cli.sh"

parse-args () {
	CMD=$1
	shift
	ARGS=$*

	case $CMD in
	    	'listen')
			PORT=$1
			"$VSH_SERVER" $PORT;;

		'list' | 'create' | 'browse' | 'extract' )
			"$VSH_CLI" $CMD "$ARGS";;
		

	    	*) "$LOGGER" 'unknown-command-error';;
	esac
}

parse-args $@