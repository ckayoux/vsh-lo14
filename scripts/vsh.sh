#!/bin/bash
LIBDIR="./lib/"
LOGGER="${LIBDIR}logger.sh"
VSH_SERVER="./vsh-server.sh"
VSH_CLI="./vsh-cli.sh"

parse-args () {
	CMD=$1
	shift
	ARGS=$*

	case $CMD in
	    	'listen')
			PORT=$1
			$VSH_SERVER $PORT;;

		'list' | 'create' | 'browse' | 'extract' )
			$VSH_CLI $CMD "$ARGS";;
		

	    	*) $LOGGER 'unknown-command-error';;
	esac
}

parse-args $@