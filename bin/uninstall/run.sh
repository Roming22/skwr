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

set -e

echo "[$MODULE_NAME] Uninstalling"
source $MODULE_DIR/etc/service.cfg

# Uninstall services
echo "[$MODULE_NAME] Deactivating"
for MODULE in $MODULE_NAME.service $MODULE_NAME-selfupdate.service; do
	if [[ -e "/etc/systemd/system/$MODULE" ]]; then
		sudo systemctl stop $MODULE
		sudo systemctl disable $MODULE 2> /dev/null
		sudo rm "/etc/systemd/system/$MODULE"
	fi
done

# Clean the system
echo "$MODULE_NAME: Cleaning configuration"
sudo systemctl daemon-reload
IMAGE_ID=`docker images -q $MODULE_NAME`
[[ ! -z "$IMAGE_ID" ]] && docker rmi $IMAGE_ID

echo "[$MODULE_NAME] Uninstalled"
