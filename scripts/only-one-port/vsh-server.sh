#!/bin/bash
SCRIPTDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"
ARCHIVESDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/archives/" &> /dev/null && pwd )"
TEMPARCHIVE="${ARCHIVESDIR}/.created_archive"
ARCHIVESEXT="sos"
USAGE="USAGE : $( basename $0 ) <port-number>"

LIBDIR="${SCRIPTDIR}lib/"
LOGGER="${LIBDIR}logger.sh"
DOWNLOAD="${LIBDIR}download.sh"
CREATE="${LIBDIR}create.sh"
#ERRLOGS="vsh_server_errlogs.txt"

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

start () (
	if test $# -eq 1	
	then
		local -i PORT="$1"
		if test "$PORT" -le 0 2>/dev/null
		then
			"$LOGGER" error "The port number must be a positive integer."
		elif test "$PORT" -lt 1024
		then	"$LOGGER" error "Forbidden socket. Choose a minimum port number of 1024."
		else
			export PORT
			export FIFO="/tmp/vsh-server-FIFO-$$"
			[ -e $FIFO ] || mkfifo "$FIFO"
			clean() { rm -f "$FIFO";}
			trap clean EXIT
			listen
		fi
	else
		echo $USAGE
	fi
)


serve() {
    local cmd archive
	read cmd archive < "$FIFO" || exit -1
	if [ `type -t $cmd` == 'function' ]
	then
		
		$cmd $archive
	else
		"$LOGGER" 'unknown-command-error'
	fi
}

listen () {
	while true
	do
		echo "listening"
		serve < "$FIFO" | netcat -l -p "$PORT" > "$FIFO" #&
	done
}

list () {
	echo -e "\nAvailable archives :"
	echo "-------------------------------------------"
	while IFS= read archive
	do
		printf " + %s\n" "$archive"
	done <<< `ls "$ARCHIVESDIR" |grep "\([a-z]\+\.$ARCHIVESEXT\)$"`
	echo "$EOT_SIGNAL"
}

create () {
	local_archive_path="$ARCHIVESDIR/$1.$ARCHIVESEXT"
	local_archive_name=`basename "$1"`
	read linescount #client sends the archive size in lines
	"$DOWNLOAD" "$local_archive_path" $linescount
	if [[ $? -eq 0 ]]
	then
		echo "Archive '$local_archive_name' has been created successfully." #afficher ce message au client
	else
		"$LOGGER" error "Error creating archive '$local_archive_name'"
	fi
	echo "$EOT_SIGNAL"
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
		"$LOGGER" error "The port number must be a positive integer."
	fi
else
	echo $USAGE
fi