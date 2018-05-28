#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`
BIN_DIR=`dirname $SCRIPT_DIR`

[[ -z "$1" ]] && echo "Specify the path of the module" && exit 1
export MODULE_DIR=`cd $1; pwd`
export MODULE_NAME=`basename $MODULE_DIR`

echo "##################################################"
echo "Starting"
source $MODULE_DIR/etc/service.cfg

while [[ true ]]; do
	# Wait for 10 to 20 minutes before checking for any update
	INTERVAL=$((600 + (RANDOM % 600) ))
	echo "Sleeping until `date --date="$INTERVAL seconds" +'%b %d %H:%M:%S'`"
	sleep $INTERVAL

	echo "##################################################"

	# Update image
	cd $MODULE_DIR
	git pull
	$BIN_DIR/build/run.sh $PWD
	cd -
	IMAGE_ID=`docker inspect $MODULE_NAME:latest | grep Id | cut -d: -f3`

	# Restart service if a new image was generated
	CONTAINER_ID=`docker ps -q -f name=^/$NAME$`
	CONTAINER_IMAGE_ID=`docker inspect $CONTAINER_ID | grep Image | grep sha256:  | cut -d: -f3`
	if [[ "$IMAGE_ID" != "$CONTAINER_IMAGE_ID" ]]; then
		echo "$MODULE_NAME: Update found, restarting $NAME.service"
		sudo systemctl stop $NAME.service
		sudo systemctl start $NAME.service
	else
		echo "$MODULE_NAME: No update"
	fi
done
