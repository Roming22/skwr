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
	DOCKER_DIR="$MODULE_DIR/docker"
	TAG=`basename $(readlink -f $MODULE_DIR)`
}

run(){
	echo "[$MODULE_NAME] Building"
	ARCHITECTURE=`lscpu | head -1 | awk '{print $2}'`
	case $ARCHITECTURE in
		armv7*) ARCHITECTURE="armv7" ;;
	esac

	docker build --rm --pull --tag $TAG:build -f $MODULE_DIR/docker/Dockerfile.$ARCHITECTURE $MODULE_DIR/docker || exit 1

	if [[ `docker images -q $TAG:latest` != `docker images -q $TAG:build` ]]; then
		docker tag $TAG:build $TAG:`date +%Y.%m%d.%H%M`
		docker tag $TAG:build $TAG:latest
	fi
	docker rmi $TAG:build >/dev/null
	echo "[$MODULE_NAME] Built"
}

init
parse_args $*
run
