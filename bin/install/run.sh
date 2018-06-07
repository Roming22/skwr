#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

export BIN_DIR=`dirname $SCRIPT_DIR`
TOOLS_DIR=`cd $SCRIPT_DIR/../.tools; pwd`

while [[ "$#" -gt 0 ]]; do
	case $1 in
		-v) set -x; VERBOSE="-v" ;;
		*) export MODULE_DIR=`$TOOLS_DIR/module_dir.sh $1`;;
	esac
	shift
done

[[ -z "$MODULE_DIR" ]] && echo "Specify the path of the module" && exit 1

export MODULE_NAME=`basename $MODULE_DIR`

set -e

echo "[$MODULE_NAME] Installing"
source $MODULE_DIR/etc/service.cfg


for SERVICE in "" "-selfupdate"; do
	[[ -e "/etc/systemd/system/$MODULE_NAME$SERVICE.service" ]] && sudo systemctl stop $MODULE_NAME$SERVICE

	# Generate systemd configuration
	envsubst < $SCRIPT_DIR/etc/service$SERVICE.template | sudo tee /etc/systemd/system/$MODULE_NAME$SERVICE.service >/dev/null

	sudo systemctl daemon-reload
	echo "[$MODULE_NAME] Activating $MODULE_NAME$SERVICE"
	sudo systemctl enable $MODULE_NAME$SERVICE 2> /dev/null
	sudo systemctl start $MODULE_NAME$SERVICE
done

echo "[$MODULE_NAME] Installed"
