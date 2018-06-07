#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

BIN_DIR=`dirname $SCRIPT_DIR`
TOOLS_DIR=`cd $SCRIPT_DIR/../.tools; pwd`

while [[ "$#" -gt 0 ]]; do
	case $1 in
		-v) set -x; VERBOSE="-v" ;;
		*) MODULE_DIR=`$TOOLS_DIR/module_dir.sh $1`;;
	esac
	shift
done

[[ -z "$MODULE_DIR" ]] && echo "Specify the path of the module" && exit 1

export MODULE_NAME=`basename $MODULE_DIR`


echo "[$MODULE_NAME] Stopping"
source $MODULE_DIR/etc/service.cfg

# Kill running container
CONTAINER_ID=`docker ps -q -f name=^/$MODULE_NAME$`
if [[ -n "$CONTAINER_ID" ]]; then
	docker stop $MODULE_NAME >/dev/null 2>&1
fi
echo "[$MODULE_NAME] Stopped"
