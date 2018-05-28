#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

while [[ "$#" -gt 0 ]]; do
        case $1 in
                -v) set -x; VERBOSE="-v" ;;
                *) MODULE_DIR=`cd $1; pwd`;;
        esac
        shift
done

[[ -z "$MODULE_DIR" ]] && echo "Specify the path of the module" && exit 1

export MODULE_NAME=`basename $MODULE_DIR`


echo "$MODULE_NAME: Stopping"
source $MODULE_DIR/etc/service.cfg

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
