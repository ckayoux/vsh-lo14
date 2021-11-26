#!/bin/bash
LIBDIR="./lib/"
LOGGER="${LIBDIR}logger.sh"

NETCAT="netcat"
which $NETCAT >/dev/null && NETCAT="netcat"
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

parse-args () {
    CMD=$1
    shift
    ARGS=$*

    case $CMD in
    	'start') start $ARGS;;

    	*) $LOGGER 'unknown-command-error';;
	esac
}


start () (
	local USAGE="USAGE : $( basename $0 ) start <port-number>"
	if test $# -eq 1	
	then
		local -i PORT="$1"
		if test "$PORT" -gt 0 2>/dev/null
		then
			export PORT
			export FIFO="/tmp/vsh-server-FIFO-$$"
			clean() { rm -f "$FIFO"; }
			trap clean EXIT
			[ -e $FIFO ] || mknod "$FIFO" p
			listen
			
		else
			$LOGGER error "The port number must be a positive integer."
		fi
	else
		echo $USAGE
	fi
)

serve() {
    local cmd archive
    while true; do
	read cmd archive || exit -1
	case $cmd in
		'list') echo "T0D0 : list all archives." ;;
		
		'create') echo "T0D0 : create archive $archive." ;;

		'browse') echo "T0D0 : browse archive $archive." ;;

		'extract') echo "T0D0 : extract archive $archive." ;;

		*) $LOGGER 'unknown-command-error' ;;
	esac
    done
}

listen () {
	while true
	do
		serve < "$FIFO" | netcat -l -p "$PORT" > "$FIFO"
	done
}

parse-args $@