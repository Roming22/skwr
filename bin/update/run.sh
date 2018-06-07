#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

BIN_DIR=`dirname $SCRIPT_DIR`
TOOLS_DIR=`cd $SCRIPT_DIR/../.tools; pwd`

while [[ "$#" -gt 0 ]]; do
	case $1 in
		-v) set -x; VERBOSE="-v" ;;
		*) MODULE_DIR=`$TOOLS_DIR/module_dir.sh $1`;;
	esac
	shift
done

[[ -z "$MODULE_DIR" ]] && echo "Specify the path of the module" && exit 1
MODULE_NAME=`basename $MODULE_DIR`

echo "##################################################"
echo "[$MODULE_NAME] Starting"
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
	IMAGE=`basename $(readlink -f $MODULE_DIR)`
	IMAGE_ID=`docker inspect $IMAGE:latest | grep Id | cut -d: -f3`

	# Restart service if a new image was generated
	CONTAINER_ID=`docker ps -q -f name=^/$MODULE_NAME$`
	CONTAINER_IMAGE_ID=`docker inspect $CONTAINER_ID | grep Image | grep sha256:  | cut -d: -f3`
	if [[ "$IMAGE_ID" != "$CONTAINER_IMAGE_ID" ]]; then
		echo "[$MODULE_NAME] Update found, restarting $MODULE_NAME.service"
		sudo systemctl stop $MODULE_NAME.service
		sudo systemctl start $MODULE_NAME.service
	else
		echo "[$MODULE_NAME] No update"
	fi

	# Clean-up old images
	docker images | egrep "^$IMAGE " | sort -r | tail -n +5 | awk '{print $3}' | xargs docker rmi
done
