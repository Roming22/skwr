#!/bin/bash

while [[ "$#" -gt 0 ]]; do
	case $1 in
		-v) set -x ;;
		*) SERVICE_DIR=`cd $1; pwd`;;
	esac
	shift
done

[[ -z "$SERVICE_DIR" ]] && echo "Specify the path of the service to install" && exit 1
SERVICE_NAME=`basename $SERVICE_DIR`

DOCKER_DIR="$SERVICE_DIR/docker"
TAG=`basename $SERVICE_DIR`

echo "$SERVICE_NAME: Building"
if [[ ! `docker build --rm --pull --tag $TAG $DOCKER_DIR` ]]; then
	exit 1
fi

exit 0
