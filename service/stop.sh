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


echo "$SERVICE_NAME: Stopping"
source $SERVICE_DIR/etc/service.cfg

# Kill running container
CONTAINER_ID=`docker ps -q -f name=^/$NAME$`
if [[ ! -z "$CONTAINER_ID" ]]; then
	docker stop $NAME >/dev/null 2>&1
	sleep 3
fi

# Delete stopped container
CONTAINER_ID=`docker ps -a -q -f name=^/$NAME$`
if [[ ! -z "$CONTAINER_ID" ]]; then
  docker rm $NAME >/dev/null 2>&1
fi
