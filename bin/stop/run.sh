#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

usage(){
	MODULES_DIR=`cd $SCRIPT_DIR/../../modules; pwd`
	echo "Modules:
`for C in $(find $MODULES_DIR -mindepth 1 -maxdepth 1 -type d -o -type l | sort); do echo "  $(basename $C)"; done`

Flags:
  -h,--help       show this message
  -v,--verbose    increase verbose level
"
}

init(){
    BIN_DIR=`dirname $SCRIPT_DIR`
    TOOLS_DIR=`cd $SCRIPT_DIR/../.tools; pwd`
}

parse_args(){
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -h|--help) usage; exit 0;;
            -v) set -x; VERBOSE="-v" ;;
            *) MODULE_DIR=`$TOOLS_DIR/module_dir.sh $1`;;
        esac
        shift
    done

    [[ -z "$MODULE_DIR" ]] && echo "Specify the path of the module" && exit 1
    MODULE_NAME=`basename $MODULE_DIR`
}

run(){
	echo "[$MODULE_NAME] Stopping"
	source $MODULE_DIR/etc/service.cfg

	# Kill running container
	CONTAINER_ID=`docker ps -q -f name=^/$MODULE_NAME$`
	if [[ -n "$CONTAINER_ID" ]]; then
		docker stop $MODULE_NAME >/dev/null 2>&1
	fi
	echo "[$MODULE_NAME] Stopped"
}

init
parse_args $*
run
