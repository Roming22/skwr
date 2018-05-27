#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`
TOOLS_DIR=`dirname $SCRIPT_DIR`

while [[ "$#" -gt 0 ]]; do
	case $1 in
		-v) set -x; VERBOSE="-v" ;;
		*) SERVICE_DIR=`cd $1; pwd`;;
	esac
	shift
done

[[ -z "$SERVICE_DIR" ]] && echo "Specify the path of the service to install" && exit 1

export SERVICE_NAME=`basename $SERVICE_DIR`

source $SERVICE_DIR/etc/service.cfg

$TOOLS_DIR/docker/build.sh $VERBOSE $SERVICE_DIR
$SCRIPT_DIR/stop.sh $VERBOSE $SERVICE_DIR

echo "##################################################"
echo "$SERVICE_NAME: Starting"

# Make sure to start the containers on a segregated network
DOCKER_NETWORK=${DOCKER_NETWORK:-$NAME}
docker network inspect $DOCKER_NETWORK >/dev/null 2>&1 || docker network create $DOCKER_NETWORK
docker run $DOCKER_OPTIONS --name $NAME --hostname $NAME $SERVICE_NAME
