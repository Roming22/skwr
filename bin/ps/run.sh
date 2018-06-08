#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

usage(){
	MODULES_DIR=`cd $SCRIPT_DIR/../../modules; pwd`
	echo "
Flags:
  -h,--help       show this message
  -v,--verbose    increase verbose level
"
}

parse_args(){
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -h|--help) usage; exit 0;;
            -v) set -x; VERBOSE="-v" ;;
        esac
        shift
    done
}

run(){
	echo "NAME: STATUS (IMAGE)"
	docker ps --format "{{.Names}}: {{.Status}} ({{.Image}})" | sort
}

parse_args $*
run
