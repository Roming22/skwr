#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

usage(){
	echo "
Options:
  -g,--get       clone a module from github
  -l,--list      list available modules
  --list-git     list modules available on github
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
			-g|--get) ACTION="get"; MODULE=$2; shift ;;
			-l|--list) ACTION="list" ;;
			--list-git) ACTION="list-git" ;;
			-h|--help) usage; exit 0 ;;
			-v) set -x; VERBOSE="-v" ;;
		esac
		shift
	done

	[[ -z "$ACTION" ]] && ACTION=list
}

get(){
	TARGET="$MODULES_DIR/$MODULE"
	if [[ -e "$TARGET" ]]; then
		echo "Module is already there"
	fi 
	git clone -q https://github.com/Roming22/skwr-$MODULE.git $TARGET
	echo "New module: $MODULE"
}

list(){
	echo "Available modules in $MODULES_DIR:"
	for M in $(find $MODULES_DIR -mindepth 1 -maxdepth 1 -type d -o -type l | sort); do
		echo "  $(basename $M)"
	done | sort
}

list-git(){
	echo "Available modules in github.com/Roming22:"
	curl -s "https://api.github.com/search/repositories?q=user:roming22&order=desc"| egrep "clone_url.*skwr-" | while read URL; do
		echo $URL | sed 's:.*/skwr-\(.*\).git",$:  \1:'
	done | sort
}

run(){
	$ACTION
}

init
parse_args $*
run
