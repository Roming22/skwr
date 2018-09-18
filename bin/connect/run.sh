#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

usage(){
	echo "
Options:
  -h,--help       show this message
  -v,--verbose    increase verbose level

Modules: 
`docker ps --format "{{ .Names}}" | sort | sed 's:^:  :'`
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
	source $MODULE_DIR/etc/service.cfg

	echo "##################################################"
	echo "[$MODULE_NAME] Connecting"

	docker exec -it $MODULE_NAME bash
}

init
parse_args $*
run
