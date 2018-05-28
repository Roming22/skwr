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

$BIN_DIR/build/run.sh $VERBOSE $MODULE_DIR
$BIN_DIR/stop/run.sh $VERBOSE $MODULE_DIR

echo "##################################################"
echo "$MODULE_NAME: Starting"

# Make sure to start the containers on a segregated network
DOCKER_NETWORK=${DOCKER_NETWORK:-$NAME}
docker network inspect $DOCKER_NETWORK >/dev/null 2>&1 || docker network create $DOCKER_NETWORK
docker run $DOCKER_OPTIONS --name $NAME --hostname $NAME $MODULE_NAME