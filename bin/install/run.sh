#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

usage(){
	MODULES_DIR=`cd $SCRIPT_DIR/../../modules; pwd`
	echo "Modules:
`for C in $(find $MODULES_DIR -mindepth 1 -maxdepth 1 -type d -o -type l | sort); do echo "  $(basename $C)"; done`

Flags:
  -h,--help       show this message
  -v,--verbose    increase verbose level
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
}

run(){
	set -e

	trap signal_handler INT
	echo "[$MODULE_NAME] Installing"
	source $MODULE_DIR/etc/service.cfg

	for SERVICE in "" "-selfupdate"; do
		[[ -e "/etc/systemd/system/$MODULE_NAME$SERVICE.service" ]] && sudo systemctl stop $MODULE_NAME$SERVICE

		# Generate systemd configuration
		envsubst < $SCRIPT_DIR/etc/service$SERVICE.template | sudo tee /etc/systemd/system/$MODULE_NAME$SERVICE.service >/dev/null

		sudo systemctl daemon-reload
		echo -n "[$MODULE_NAME] Activating $MODULE_NAME$SERVICE "
		sudo systemctl enable $MODULE_NAME$SERVICE 2> /dev/null
		sudo systemctl start $MODULE_NAME$SERVICE
		while ! `systemctl status $MODULE_NAME$SERVICE | grep -q "Active: active (running)"`; do
			echo -n "."
			sleep 1
		done
		echo
	done

	START_TIME=`systemctl status $MODULE_NAME | grep Active: | awk '{print $6" "$7}'`
	timeout 300 cat <(wait_for_service) || service_error
	echo "[$MODULE_NAME] Installed"
}

wait_for_service(){
	echo -n "[$MODULE_NAME] Waiting for service to be online "
	COUNT=1
	while ! sudo journalctl -u $MODULE_NAME --since="$START_TIME" | grep -q "\[$MODULE_NAME\] Started"; do
		case $COUNT in
			4) echo -ne "\b\b\b   \b\b\b"; COUNT=0 ;;
			*) echo -n "." ;;
		esac
		sleep 1
		COUNT=$((COUNT + 1))
	done
}

service_error(){
	sleep 2
	sudo journalctl -u $MODULE_NAME --since="$START_TIME"
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
