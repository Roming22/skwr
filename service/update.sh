#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`
TOOLS_DIR=`dirname $SCRIPT_DIR`

[[ -z "$1" ]] && echo "Specify the path of the service to install" && exit 1
export SERVICE_DIR=`cd $1; pwd`
export SERVICE_NAME=`basename $SERVICE_DIR`

echo "##################################################"
echo "Starting"
source $SERVICE_DIR/etc/service.cfg

while [[ true ]]; do
	# Wait for 10 to 20 minutes before checking for any update
	INTERVAL=$((600 + (RANDOM % 600) ))
	echo "Sleeping until `date --date="$INTERVAL seconds" +'%b %d %H:%M:%S'`"
	sleep $INTERVAL

	echo "##################################################"
	CONTAINER_ID=`docker ps -q -f name=^/$NAME$`
	CONTAINER_IMAGE_ID=`docker inspect $CONTAINER_ID | grep Image | grep sha256:  | cut -d: -f3`

	$TOOLS_DIR/docker/build.sh $SERVICE_DIR
	IMAGE_ID=`docker inspect $SERVICE_NAME:latest | grep Id | cut -d: -f3`
	
	if [[ "$IMAGE_ID" != "$CONTAINER_IMAGE_ID" ]]; then
		echo "$SERVICE_NAME: Update found, restarting $NAME.service"
		systemctl restart $NAME.service
	else
		echo "$SERVICE_NAME: No update"
	fi
done
