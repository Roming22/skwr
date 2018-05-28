#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`
BIN_DIR=`dirname $SCRIPT_DIR`

while [[ "$#" -gt 0 ]]; do
	case $1 in
		-v) set -x; VERBOSE="-v" ;;
		*) MODULE_DIR=`cd $1; pwd`;;
	esac
	shift
done

[[ -z "$MODULE_DIR" ]] && echo "Specify the path of the module" && exit 1

export MODULE_NAME=`basename $MODULE_DIR`

source $MODULE_DIR/etc/service.cfg

echo "##################################################"
echo "$MODULE_NAME: Connecting"

# Make sure to start the containers on a segregated network
docker exec -it $NAME bash
