#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

usage(){
MODULES_DIR=`cd $SCRIPT_DIR/../../modules; pwd`
	echo "
Options:
  -i,--ip         IP of the router on the LAN

Flags:
  -h,--help       show this message
  -v,--verbose    increase verbose level
"
}

init(){
	source /etc/os-release
}

parse_args(){
	while [[ "$#" -gt 0 ]]; do
		case $1 in
			-i|--ip) export LAN_IP=$2; shift ;;
			-h|--help) usage; exit 0 ;;
			-v) set -x; VERBOSE="-v" ;;
			*) echo "unknown arg: $1"; usage; exit 1;;
		esac
		shift
	done

	[[ -z "$LAN_IP" ]] && echo "--ip is mandatory" && usage && exit 1
}

run(){
	$SCRIPT_DIR/$ID/run.sh
}

init
parse_args $*
run
