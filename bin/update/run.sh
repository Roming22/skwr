#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

usage(){
	MODULES_DIR=`cd $SCRIPT_DIR/../../modules; pwd`
	echo "
Options:
  -h,--help       show this message
  -d,--daemon     run the update continuously
  -v,--verbose    increase verbose level

Modules:
`systemctl | egrep "^skwr-" | sed 's:^skwr-\(.*\).service .*:\1:'`
"
}

init(){
    BIN_DIR=`dirname $SCRIPT_DIR`
    TOOLS_DIR=`cd $SCRIPT_DIR/../.tools; pwd`
}

parse_args(){
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -h|--help) usage; exit 0;;
            -d|--daemon) DAEMON="true" ;;
            -v) set -x; VERBOSE="-v" ;;
            *) MODULE_DIRS=`$MODULE_DIRS $1`;;
        esac
        shift
    done

    [[ -z "$MODULE_DIRS" ]] && MODULE_DIRS=`systemctl | egrep "^skwr-" | sed 's:^skwr-\(.*\).service .*:\1:'`
	[[ -z "$MODULE_DIRS" ]] && echo "No module to process" && exit 1
	MODULE_DIRS=("$MODULE_DIRS")
}

run(){
	echo "##################################################"
	echo "Modules:"
	echo "$MODULE_DIRS"
	[[ -n "$DAEMON" ]] && run_daemon || update_images
	exit $?
	echo "Done"
}

run_daemon(){
	while [[ true ]]; do
		# Wait for 10 to 20 minutes before checking for any update
		INTERVAL=$((600 + (RANDOM % 600) ))
		echo "Sleeping until `date --date="$INTERVAL seconds" +'%b %d %H:%M:%S'`"
		sleep $INTERVAL
		update_images
	done
}

update_images(){
	for MODULE_DIR in $MODULE_DIRS; do
		update_image
	done
}

update_image(){
	MODULE_DIR=`$TOOLS_DIR/module_dir.sh $MODULE_DIR`
	MODULE_NAME=`basename $MODULE_DIR`

	echo "##################################################"
	echo "[$MODULE_NAME] Starting"
	source $MODULE_DIR/etc/service.cfg
	cd $MODULE_DIR
	git pull
	$BIN_DIR/build/run.sh $PWD
	cd -
	IMAGE=skwr/`basename $MODULE_DIR`
	IMAGE_ID=`docker inspect $IMAGE:latest | grep Id | cut -d: -f3`

	# Restart service if a new image was generated
	CONTAINER_ID=`docker ps -q -f name=^/$MODULE_NAME$`
	CONTAINER_IMAGE_ID=`docker inspect $CONTAINER_ID | grep Image | grep sha256:  | cut -d: -f3`
	if [[ "$IMAGE_ID" != "$CONTAINER_IMAGE_ID" ]]; then
		SERVICE_NAME="skwr-$MODULE_NAME.service"
		echo "[$MODULE_NAME] Update found, restarting $SERVICE_NAME"
		sudo systemctl stop $SERVICE_NAME
		sudo systemctl start $SERVICE_NAME
	else
		echo "[$MODULE_NAME] No update"
	fi

	# Clean-up old images
	docker images | egrep "^$IMAGE " | sort -r | tail -n +5 | awk '{print $3}' | while read IMAGE; do
		docker rmi $IMAGE
	done
}

init
parse_args $*
run
