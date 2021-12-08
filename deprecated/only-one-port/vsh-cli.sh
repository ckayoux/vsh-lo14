#!/bin/bash
SCRIPTDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"
LAUNCHER="${SCRIPTDIR}vsh.sh"
ARCHIVESDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/archives" &> /dev/null && pwd )"
TEMPARCHIVE="/tmp/.created_archive"

LIBDIR="${SCRIPTDIR}lib/"
LOGGER="${LIBDIR}logger.sh"
CREATE="${LIBDIR}create.sh"
TRANSMISSION_RECEIVER="${LIBDIR}receive-transmission.sh"

USAGE="CLIENT COMMANDS : list <server_name> <port>, {create|browse|extract} <server_name> <port> <archive_name>"

DEFAULT_SERVER_NAME='localhost'
DEFAULT_ARCHIVE_PREFIX='archive'

EOT_SIGNAL="𰻞𰻞麵"

NETCAT="netcat"
which $NETCAT >/dev/null
if test $? -ne 0
then
	NETCAT="nc"
	which $NETCAT >/dev/null
	if test $? -ne 0
	then
		"$LOGGER" 'Could not find a netcat executable on your system.'
		exit 1
	fi
fi

echo_transmission () {
	while read line
	do
		if [ "$line" == "$EOT_SIGNAL" ]
		then
			break
		else
			printf "%s\n" "$line"
		fi
	done
}

connect () {
	export SERVER=$1
	export PORT=$2
	export OUTGOING="/tmp/vsh-cli-OUTGOING-$$"
	export INCOMING="/tmp/vsh-cli-INCOMING-$$"
	clean() { rm -f "$OUTGOING";rm -f "$INCOMING";}
	[ -e $OUTGOING ] || mknod "$OUTGOING" p
	[ -e $INCOMING ] || mknod "$INCOMING" p
	trap clean EXIT
	netcat "$SERVER" "$PORT" < "$OUTGOING"  > "$INCOMING"  &
	export NCPID=$!
	exec 3> "$OUTGOING"
}

connection_is_active () {
	if test -n "$(ps $NCPID |tail +2)" #test if NCPID is running
	then return 0
	else return -1
	fi
}

disconnect () {
	connection_is_active
	if test $? -eq 0
	then kill $NCPID
	else "$LOGGER" error "Connection with $SERVER : $PORT couldn't be established."
	fi
	exec >&3-
}


list () {
	echo "list" >&3
	echo-transmission <"$INCOMING"
	disconnect
}

echo-transmission () {
	while read line
	do
		if [ "$line" == "$EOT_SIGNAL" ]
		then
			break
		else
			echo "$line"
		fi
	done
}

create () {
	distant_archive=$1
	"$CREATE" "$TEMPARCHIVE"
	echo "create $distant_archive" >&3
	cat "$TEMPARCHIVE"|wc -l >&3
	while read -r line
	do
		printf "%s\n" "$line" >&3
	done <"$TEMPARCHIVE"
	echo-transmission <"$INCOMING" #echoes the servers answer
	disconnect
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
		"$LOGGER" 'error' "Too many arguments, only $1 expected"
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
		"$LOGGER" 'error' "No $missing provided"
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
		export USAGE="USAGE : $( basename "$LAUNCHER" ) -list <server_name> <port>"
		check-arg-presence -s $server_name || exit -1 
		check-arg-presence -p $port || exit -1
		check-too-many-args 2 || exit -1 
		connect $server_name $port
		list;;

	'create' | 'browse' | 'extract' )
		export USAGE="USAGE : $( basename "$LAUNCHER" ) -$CMD <server_name> <port> <archive_name>"
		check-arg-presence -s $server_name || exit -1 
		check-arg-presence -p $port || exit -1
		check-arg-presence -a $archive_name || exit -1
		check-too-many-args 3 || exit -1 
		connect $server_name $port
		$CMD $archive_name;;
	


    	*) "$LOGGER" 'unknown-command-error';;
	esac
}

parse-args $@