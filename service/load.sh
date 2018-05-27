#!/bin/bash
export SCRIPT_DIR=`cd $(dirname $0); pwd`
export TOOLS_DIR=`dirname $SCRIPT_DIR`
export PROJECT_DIR=`dirname $TOOLS_DIR`

while [[ "$#" -gt 0 ]]; do
	case $1 in
		-v) set -x; VERBOSE="-v" ;;
		*) export SERVICE_DIR=`cd $1; pwd`;;
	esac
	shift
done

[[ -z "$SERVICE_DIR" ]] && echo "Specify the path of the service to install" && exit 1

export SERVICE_NAME=`basename $SERVICE_DIR`

set -e

echo "$SERVICE_NAME: Installing"
source $SERVICE_DIR/etc/service.cfg

# Generate systemd configuration
envsubst < $SCRIPT_DIR/etc/service.template | sudo tee /etc/systemd/system/$NAME.service >/dev/null
envsubst < $SCRIPT_DIR/etc/selfupdate.template | sudo tee /etc/systemd/system/$NAME-selfupdate.service >/dev/null

# Activate services
echo "$SERVICE_NAME: Activating"
sudo systemctl daemon-reload
for SERVICE in $NAME.service $NAME-selfupdate.service; do
	sudo systemctl enable $SERVICE 2> /dev/null
	sudo systemctl restart $SERVICE
done

echo "$SERVICE_NAME: Success"
