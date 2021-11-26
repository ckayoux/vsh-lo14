#!/bin/bash
USAGE="USAGE : $( basename $0 ) <port-number>"

LIBDIR="./lib/"
LOGGER="${LIBDIR}logger.sh"
#ERRLOGS="vsh_server_errlogs.txt"

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

start () (
	if test $# -eq 1	
	then
		local -i PORT="$1"
		if test "$PORT" -le 0 2>/dev/null
		then
			$LOGGER error "The port number must be a positive integer."
		elif test "$PORT" -lt 1024
		then	$LOGGER error "Forbidden socket. Choose a minimum port number of 1024."
		else
			export PORT
			export FIFO="/tmp/vsh-server-FIFO-$$"
			clean() { rm -f "$FIFO"; }
			trap clean EXIT
			[ -e $FIFO ] || mknod "$FIFO" p
			listen
			
		fi
	else
		echo $USAGE
	fi
)

serve() {
    local cmd archive
    while true; do
	read cmd archive|| exit -1
	if [ `type -t $cmd` == 'function' ]
	then
		$cmd $archive
	else
		$LOGGER 'unknown-command-error'
	fi
    done
}

listen () {
	while true
	do
		serve < "$FIFO" | netcat -l -p "$PORT" > "$FIFO"
	done
}

list () {
	echo "T0D0 : list all archives."
}

create () {
	echo "T0D0 : create archive $1."
}

browse () {
	echo "T0D0 : browse archive $1."
}

extract () {
	echo "T0D0 : extract archive $1."
}

if test $# -eq 1	
then
	declare -i PORT="$1"
	if test "$PORT" -gt 0 2>/dev/null
	then
		export PORT
		start $PORT
			
	else
		$LOGGER error "The port number must be a positive integer."
	fi
else
	echo $USAGE
fi