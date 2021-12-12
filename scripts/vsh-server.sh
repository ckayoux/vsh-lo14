#!/bin/bash
SCRIPTDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"
ARCHIVESDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/archives/" &> /dev/null && pwd )"
TEMPARCHIVE="${ARCHIVESDIR}/.created_archive"
ARCHIVESEXT="sos"
USAGE="USAGE : $( basename $0 ) <port-number...>"

LIBDIR="${SCRIPTDIR}lib/"
LOGGER="${LIBDIR}logger.sh"
DOWNLOAD="${LIBDIR}download.sh"
CREATE="${LIBDIR}create.sh"
BROWSE="${LIBDIR}browse.sh"
#ERRLOGS="vsh_server_errlogs.txt"

EOT_SIGNAL="𰻞𰻞麵"
PROMPT_SIGNAL="( ͡°( ͡° ͜ʖ( ͡° ͜ʖ ͡°)ʖ ͡°) ͡°)"

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

start () {
	i=0
	while read port
	do
		local -i P="$port"
		if test "$P" -le 0 2>/dev/null
		then
			"$LOGGER" error "The port number must be a positive integer (got $P)."
		elif test "$P" -lt 1024
		then	"$LOGGER" error "$P : Reserved socket. Choose a minimum port number of 1024."
		else
			((i++))
			export PORT$i=$P
			export FIFO$i="/tmp/vsh-server-FIFO-$P"
			[ -e "$(eval echo "\${FIFO$i}")" ] || mkfifo "$(eval echo "\${FIFO$i}")"
		fi
	done < <(sed 's/ /\n/g' <<< "$*")
	export PORTSNUMBER=$i
	for ((k=1;k<=$PORTSNUMBER;k++))
	do
		echo "listening on $(eval echo "\${PORT$k}")"'...'
		listen $k &
		export LISTENPID$k="$!"
	done
}


serve() {
    local cmd archive
	read cmd archive || exit -1 #<"$FIFO" || exit -1
	if [ `type -t $cmd` == 'function' ]
	then
		$cmd $archive
	else 
		"$LOGGER" 'unknown-command-error'
	fi
}

listen () {
	z=0
	while true;
	do
		local lport="$(eval echo "\${PORT$1}")"
		local lfifo="$(eval echo "\${FIFO$1}")"
		serve < "$lfifo" | netcat -l -p $lport > "$lfifo"

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
	echo "creating $1"
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
	local_archive_path="$ARCHIVESDIR/$1.$ARCHIVESEXT"
	local_archive_name=`basename "$1"`
	"$BROWSE" "$local_archive_path"
	echo "$EOT_SIGNAL"
}

extract () {
	echo "T0D0 : extract archive $1."
}

clean() { 
		for ((k=1;k<=$PORTSNUMBER;k++))
		do
			#kill -9 "$(eval echo \$LISTENPID$k)" > /dev/null
			fuser -k "$(eval echo "\${PORT$k}")"/tcp > /dev/null 2>&1
			rm -f "$(eval echo "\${FIFO$k}")"
		done
}

if test $# -eq 0	
then
	echo $USAGE
else
	PORTSNUMBER=$#
	trap clean EXIT
	start "$*"
	echo -e "\nType in 'stop' to shut the server down."
	while read stop
	do
		if [ "$stop" == "stop" ]
		then
			echo "Shutting down the server..."
			pkill -P $$
			exit
		fi
	done
fi