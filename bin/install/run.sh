#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

usage(){
	MODULES_DIR=`cd $SCRIPT_DIR/../../modules; pwd`
	echo "
Options:
  -h,--help       show this message
  -v,--verbose    increase verbose level

Modules:
`for C in $(find $MODULES_DIR -mindepth 1 -maxdepth 1 -type d -o -type l | sort); do echo "  $(basename $C)"; done`
"
}

init(){
    export BIN_DIR=`dirname $SCRIPT_DIR`
    TOOLS_DIR=`cd $SCRIPT_DIR/../.tools; pwd`
}

parse_args(){
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -h|--help) usage; exit 0;;
            -v) set -x; VERBOSE="-v" ;;
            *) export MODULE_DIR=`$TOOLS_DIR/module_dir.sh $1`;;
        esac
        shift
    done

    [[ -z "$MODULE_DIR" ]] && echo "Specify the path of the module" && exit 1
    MODULE_NAME=`basename $MODULE_DIR`
    [[ "${MODULE_NAME:0:4}" = "skwr" ]] && SERVICE_NAME="$MODULE_NAME" || SERVICE_NAME="skwr-$MODULE_NAME"
}

run(){
	set -e

	trap signal_handler INT
	echo "[$MODULE_NAME] Installing"
	source $MODULE_DIR/etc/service.cfg

	[[ -e "/etc/systemd/system/$SERVICE_NAME" ]] && sudo systemctl stop $SERVICE_NAME

	# Generate systemd configuration and start service
	envsubst < $SCRIPT_DIR/etc/service.template | sudo tee /etc/systemd/system/$SERVICE_NAME.service >/dev/null
	sudo systemctl daemon-reload
	echo -n "[$MODULE_NAME] Activating $SERVICE_NAME"
	sudo systemctl enable $SERVICE_NAME 2> /dev/null
	sudo systemctl start $SERVICE_NAME
	while ! `systemctl status $SERVICE_NAME | grep -q "Active: active (running)"`; do
		echo -n "."
		sleep 1
	done
	echo

	# Wait for service to be online
	START_TIME=`systemctl status $SERVICE_NAME | grep Active: | awk '{print $6" "$7}'`
	timeout 300 cat <(wait_for_service) || service_error
	echo "[$MODULE_NAME] Installed"

	install_selfupdate
}

wait_for_service(){
	echo -n "[$MODULE_NAME] Waiting for service to be online "
	COUNT=1
	while ! sudo journalctl -u $SERVICE_NAME --since="$START_TIME" | grep -q "\[$MODULE_NAME\] Started"; do
		case $COUNT in
			4) ;;
			5) echo -ne "\b\b\b   \b\b\b"; COUNT=0 ;;
			*) echo -n "." ;;
		esac
		sleep 1
		COUNT=$((COUNT + 1))
	done
	echo
}

install_selfupdate(){
	SERVICE_NAME="selfupdate"
	SERVICE_FILE="skwr_$SERVICE_NAME.service"
	envsubst < $SCRIPT_DIR/etc/selfupdate.template > /tmp/$SERVICE_FILE

	if [[ ! -e "/etc/systemd/system/$SERVICE_FILE" ]]; then
		INSTALL="true"
	else
		cmp -s /tmp/$SERVICE_FILE /etc/systemd/system/$SERVICE_FILE || INSTALL="true"
	fi

	if [[ -n "$INSTALL" ]]; then
		echo
		echo "[$SERVICE_NAME] Installing"
		sudo cp /tmp/$SERVICE_FILE /etc/systemd/system/
		sudo systemctl daemon-reload
		sudo systemctl enable $SERVICE_FILE
		sudo systemctl restart $SERVICE_FILE
		echo "[$SERVICE_NAME] Installed"
	fi
	rm /tmp/$SERVICE_FILE
}

service_error(){
	echo
	sleep 2
	sudo journalctl -u $SERVICE_NAME --since="$START_TIME"
	$BIN_DIR/uninstall/run.sh $VERBOSE $MODULE_DIR
	exit 1
}

signal_handler(){
	echo
	$BIN_DIR/uninstall/run.sh $VERBOSE $MODULE_DIR
}

init
parse_args $*
run
