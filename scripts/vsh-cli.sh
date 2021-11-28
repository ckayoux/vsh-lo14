#!/bin/bash
LIBDIR="./lib/"
LOGGER="${LIBDIR}logger.sh"

LAUNCHER="./vsh.sh"
USAGE="CLIENT COMMANDS : list <server_name> <port>, {create|browse|extract} <server_name> <port> <archive_name>"

DEFAULT_SERVER_NAME='localhost'
DEFAULT_ARCHIVE_PREFIX='archive'

NETCAT="netcat"
which $NETCAT >/dev/null
if test $? -ne 0
then
	NETCAT="nc"
	which $NETCAT >/dev/null
	if test $? -ne 0
	then
		$LOGGER 'Could not find a netcat executable on your system.'
		exit 1
	fi
fi

connect () {
	export SERVER=$1
	export PORT=$2
	echo "T0D0 : connect to $SERVER, port $PORT."
}

list () {
	echo "T0D0 : list all archives on $SERVER."
}

create () {
	archive=$1
	echo "T0D0 : create archive $archive of $(pwd) on $SERVER."
}

browse () {
	echo "T0D0 : Enter browse mode for $1 on $SERVER"
}

extract () {
	echo "T0D0 : Extract $1 of $SERVER in $(pwd)."
}

check-too-many-args () {
	expected=$1
	argc=$(echo $ARGS |wc -w)
	if test $argc -gt $expected
	then
		$LOGGER 'error' "Too many arguments, only $1 expected"
		echo $USAGE
		return -1	
	else return 0
	fi
}

check-arg-presence () {
	#-s : server ; -p : port ; -a : archive
	missing="arguments"
	OPTIND=1
	while getopts "spa" o
	do	
		case "${o}" in
			s) missing="server name";;
			p) missing="port";;
			a) missing="archive name";;
		esac
	done
	shift $((OPTIND-1))
	if test -z $1
	then
		$LOGGER 'error' "No $missing provided"
		echo $USAGE
		return -1
	else
		return 0
	fi
}

parse-args () {
	CMD=$1
	shift
	ARGS=$*
	
	server_name=$1
	port=$2
	archive_name=$3
	case $CMD in

	'list')
		export USAGE="USAGE : $( basename $LAUNCHER ) -list <server_name> <port>"
		check-arg-presence -s $server_name || exit -1 
		check-arg-presence -p $port || exit -1
		check-too-many-args 2 || exit -1 
		connect $server_name $port
		list;;

	'create' | 'browse' | 'extract' )
		export USAGE="USAGE : $( basename $LAUNCHER ) -$CMD <server_name> <port> <archive_name>"
		check-arg-presence -s $server_name || exit -1 
		check-arg-presence -p $port || exit -1
		check-arg-presence -a $archive_name || exit -1
		check-too-many-args 3 || exit -1 
		connect $server_name $port
		$CMD $archive_name;;
	


    	*) $LOGGER 'unknown-command-error';;
	esac
}

parse-args $@