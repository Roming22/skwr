#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`
TOOLS_DIR=`dirname $SCRIPT_DIR`
PROJECT_DIR=`dirname $TOOLS_DIR`

while [[ "$#" -gt 0 ]]; do
	case $1 in
		-v) set -x; VERBOSE="-v" ;;
		*) SERVICE_DIR=`cd $1; pwd`;;
	esac
	shift
done

[[ -z "$SERVICE_DIR" ]] && echo "Specify the path of the service to install" && exit 1

SERVICE_NAME=`basename $SERVICE_DIR`

set -e

echo "$SERVICE_NAME: Uninstalling"
source $SERVICE_DIR/etc/service.cfg

# Uninstall services
echo "$SERVICE_NAME: Deactivating"
for SERVICE in $NAME.service $NAME-selfupdate.service; do
	if [[ -e "/etc/systemd/system/$SERVICE" ]]; then
		sudo systemctl stop $SERVICE
		sudo systemctl disable $SERVICE 2> /dev/null
		sudo rm "/etc/systemd/system/$SERVICE"
	fi
done

# Clean the system
echo "$SERVICE_NAME: Cleaning configuration"
sudo systemctl daemon-reload
IMAGE_ID=`docker images -q $SERVICE_NAME`
[[ ! -z "$IMAGE_ID" ]] && docker rmi $IMAGE_ID

echo "$SERVICE_NAME: Success"
