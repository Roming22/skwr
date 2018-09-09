#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

usage(){
	echo "Options:
  -l,--list      list available modules

Flags:
  -h,--help       show this message
  -v,--verbose    increase verbose level
"
}

init(){
	BIN_DIR=`dirname $SCRIPT_DIR`
	MODULES_DIR=`cd $SCRIPT_DIR/../../modules; pwd`
	TOOLS_DIR=`cd $SCRIPT_DIR/../.tools; pwd`
}

parse_args(){
	while [[ "$#" -gt 0 ]]; do
		case $1 in
			-l|--list) ACTION="list" ;;
			-h|--help) usage; exit 0 ;;
			-v) set -x; VERBOSE="-v" ;;
			*) MODULE_DIR=`$TOOLS_DIR/module_dir.sh $1` ;;
		esac
		shift
	done

	[[ -z "$ACTION" ]] && ACTION=list
}

run(){
	case $ACTION in
		list)
			echo "Available modules in $MODULES_DIR:"
			for C in $(find $MODULES_DIR -mindepth 1 -maxdepth 1 -type d -o -type l | sort); do
				echo "  $(basename $C)";
			done
			;;
	esac
}

init
parse_args $*
run
