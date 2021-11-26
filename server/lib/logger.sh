#!/bin/bash

parse-args () {
    CMD=$1
    shift
    ARGS=$*

    $CMD "$ARGS"
}

error () {
    if test -n "$1"
    then
        echo "!-- $1 --!"
    fi
}

unknown-command-error () {
    error "Unknown command"
}

see-help () {
	echo "Use option '--help' to list the available commands." 
}
parse-args $@


