#!/bin/bash

parse-args () {
    CMD=$1
    shift
    ARGS=$*

    case $CMD in
        'error') error "$ARGS";;

        *) unknown-command-error;;
    esac
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

parse-args $@


