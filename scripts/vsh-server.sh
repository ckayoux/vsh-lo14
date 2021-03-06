#!/bin/bash
SCRIPTDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"
ARCHIVESDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/archives/" &> /dev/null && pwd )"
TEMPARCHIVE="${ARCHIVESDIR}/.created_archive"
ARCHIVESEXT="sos"
USAGE="USAGE : $( basename $0 ) <(port|ports-range)...>"

LIBDIR="${SCRIPTDIR}lib/"
LOGGER="${LIBDIR}logger.sh"
DOWNLOAD="${LIBDIR}download.sh"
CREATE="${LIBDIR}create.sh"
BROWSE="${LIBDIR}browse.sh"
#ERRLOGS="vsh_server_errlogs.txt"

EOT_SIGNAL="𰻞𰻞麵"
PROMPT_SIGNAL="( ͡°( ͡° ͜ʖ( ͡° ͜ʖ ͡°)ʖ ͡°) ͡°)"

MUTEXFILE="/tmp/vsh-server-$$-MUTEX"

publicip=`curl -s api.ipify.org 2> /dev/null`

SERVERPID=$$

NETCAT="netcat"
which $NETCAT > /dev/null 2>&1
if test $? -ne 0
then
	NETCAT="nc"
	which $NETCAT > /dev/null 2>&1
	if test $? -ne 0
	then
		"$LOGGER" error 'Could not find a netcat executable on your system.'
		exit 1
	fi
fi

if test -e "$ARCHIVESDIR"
then
	echo -n
else
	mkdir "$( dirname -- "${BASH_SOURCE[0]}" )/archives/"
	ARCHIVESDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/archives/" &> /dev/null && pwd )"
fi

start () {
	i=0
	while read port
	do
		if test -z "$port"
		then echo "$USAGE"; break
		fi
		local -i P="$port"
		if test "$P" -le 0 2>/dev/null
		then
			"$LOGGER" error "The port number must be a positive integer (got $port)."
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
	listening=0
	for ((k=1;k<=$PORTSNUMBER;k++))
	do	
		if test -z "$(ss  -tulpn |grep 'LISTEN\s\+\([0-9]\s\+\)\{2\}0.0.0.0:'"$(eval echo "\${PORT$k}")" )"
		then
			echo "Listening on $(eval echo "\${PORT$k}")"'...'
			((listening++))
			listen $k &
			export LISTENPID$k="$!"
		else
			"$LOGGER" error "$(eval echo "\${PORT$k}") is already in use"
		fi
	done
	if test $listening -eq 0
	then exit -1
	fi
}


serve() {
    #local cmd archive
	lastcmd=""
	#read cmd archive || return -1 #|| exit -1 #<"$FIFO" || exit -1
	#if [ `type -t $cmd` == 'function' ]
	#then
	#	$cmd $archive
	#else 
	#	"$LOGGER" 'unknown-command-error'
	#fi
	while [[ $iteration -eq 1 || "$lastcmd" == "archive_exists" ]]
	read cmd archive || exit -1 
	do
		type=`type -t "$cmd"`
		if [[ -n "$type" && "$type" == 'function' ]]
		then
			$cmd $archive
		else 
			"$LOGGER" 'unknown-command-error'
		fi
		((iteration++))
		lastcmd="$cmd"
	done
}

listen () {
	z=0
	while true;
	do
		lport="$(eval echo "\${PORT$1}")"
		lfifo="$(eval echo "\${FIFO$1}")"
		serve < "$lfifo" | "$NETCAT" -l -p $lport > "$lfifo" 2> /dev/null
	done
}

archive_exists () {
	apath="$ARCHIVESDIR/$1.$ARCHIVESEXT"
	aname=`basename "$apath" ".$ARCHIVESEXT"`
	mutex="$(cat $MUTEXFILE |grep '^'"$aname"'$')"
	if test -e "$apath"
	then
		if test -n "$mutex"
		then
			"$LOGGER" error "'$aname' is already being browsed by another user"
		else
			echo "$EOT_SIGNAL"
		fi
	else
		if test -n "$publicip" -a $? -eq 0
		then
			"$LOGGER" error "Archive '$aname' doesn't exist on $publicip"
		else
			"$LOGGER" error "Archive '$aname' doesn't exist on the server"
		fi
	fi
}

list () {
	if test -n "$publicip"
		then echo -e "\nArchives of $publicip :"
		else echo -e "\nAvailable archives :"
	fi
	echo "-------------------------------------------"
	readArchivesCount=0
	while IFS= read -r archive
	do
		if test -n "$archive"
		then
			aname=`basename "$archive" ".$ARCHIVESEXT"`
			inUse="$(cat $MUTEXFILE |grep '^'"$aname"'$')"
			printf " + %s" "$aname"
			if test -n "$inUse"
			then
				echo -en "\t\t(already in use)"
			fi
			echo
			((readArchivesCount++))
		fi	
	done <<< "$(ls "$ARCHIVESDIR" |grep "\([a-z]\+\.$ARCHIVESEXT\)$")"
	if test "$readArchivesCount" -eq 0
	then
		"$LOGGER" error "No archives were found on this server"
	fi
	echo "$EOT_SIGNAL"
}

create () {
	local_archive_path="$ARCHIVESDIR/$1.$ARCHIVESEXT"
	aname=`basename "$1" ".$ARCHIVESEXT"`
	mutex="$(cat $MUTEXFILE |grep '^'"$aname"'$')"
	if test -n "$mutex"
	then "$LOGGER" error "$aname is already being browsed by another user"
	else
		echo "creating $1"
		read linescount #client sends the archive size in lines
		"$DOWNLOAD" "$local_archive_path" $linescount
		if [[ $? -eq 0 ]]
		then
			echo "Archive '$aname' has been created successfully." #afficher ce message au client
		else
			"$LOGGER" error "Error creating archive '$aname'"
		fi
	fi
	echo "$EOT_SIGNAL"
}

browse () {
	local_archive_path="$ARCHIVESDIR/$1.$ARCHIVESEXT"
	aname=`basename "$apath" ".$ARCHIVESEXT"`
	echo "$aname" >> "$MUTEXFILE" #prevent two users from browsing simultaneously
	"$BROWSE" "$local_archive_path"
	if test -w "$MUTEXFILE"
	then
		sed -i '/^'"$aname"'$/d' "$MUTEXFILE"
	fi
	echo "$EOT_SIGNAL"
}

extract () {
	local_archive_path="$ARCHIVESDIR/$1.$ARCHIVESEXT"
	shift
	extraction_path="$*"
	aname=`basename "$apath" ".$ARCHIVESEXT"`
	echo "$aname" >> "$MUTEXFILE" #prevent an user from browsing while archive is being posted to 

	echo "$PROMPT_SIGNAL"
	cat "$local_archive_path"|wc -l #sending line count of archive to prepare the download ...
	while read -r line #sending archive content
	do
		printf "%s\n" "$line"
	done < "$local_archive_path"
	echo "Extracting archive $aname at '$extraction_path' ..." 

	if test -w "$MUTEXFILE"
	then
		sed -i '/^'"$aname"'$/d' "$MUTEXFILE"
	fi
	echo "$EOT_SIGNAL"
}

clean() { 
		echo "Shutting down the server..."
		pkill -P "$SERVERPID"
		if test -e "$MUTEXFILE"
		then rm "$MUTEXFILE" 2> /dev/null
		fi
		for ((k=1;k<=$PORTSNUMBER;k++))
		do
			fuser -k "$(eval echo "\${PORT$k}")"/tcp > /dev/null 2>&1
			rm -f "$(eval echo "\${FIFO$k}")"
		done
		exit 0
}

if test $# -eq 0	
then
	echo $USAGE
else
	touch "$MUTEXFILE"
	PORTSNUMBER=$#
	trap clean INT
	start "$*"
	echo -e "\nType in 'stop' to shut the server down."
	while read stop
	do
		if [ "$stop" == "stop" ]
		then
			clean
		fi
	done
fi