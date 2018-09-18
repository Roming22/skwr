#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`
set -e

usage(){
	echo "
Options:
  -h,--help       show this message
  -v,--verbose    increase verbose level
"
}

init(){
	[[ -e "/etc/os-release" ]] && source /etc/os-release || ID=""
}

parse_args(){
	while [[ "$#" -gt 0 ]]; do
		case $1 in
			-h|--help) usage; exit 0 ;;
			-v) set -x; VERBOSE="-v" ;;
			*) echo "unknown arg: $1"; usage; exit 1 ;;
		esac
		shift
	done
}

run(){
	[[ -z "$ID" ]] && echo "[FATAL] Could not find the OS name" && exit 1
	$SCRIPT_DIR/$ID/run.sh
	setup_skwr
}

setup_skwr(){
    SKWR_DIR=`cd $SCRIPT_DIR/../..; pwd`
    if [[ -L "/usr/local/bin/skwr" ]]; then
		rm -f "/usr/local/bin/skwr"
	fi
    ln -s "$SKWR_DIR/bin/skwr.sh" "/usr/local/bin/skwr"
}

init
parse_args $*
run
