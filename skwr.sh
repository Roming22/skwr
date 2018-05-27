#!/bin/bash
SCRIPT_DIR=`cd $(dirname $(readlink -f $0)); pwd`
ACTION=$1
shift

SERVICE_DIR="$PWD"
while [[ "$#" -gt 0 ]]; do
	case $1 in
		-v) set -x; VERBOSE="-v" ;;
		*) SERVICE_DIR=`cd $1; pwd`;;
	esac
	shift
done


BIN=`find $SCRIPT_DIR -name $ACTION.sh | head -1`

while [[ ! -e "$SERVICE_DIR/docker/Dockerfile" ]]; do
	SERVICE_DIR=`cd $SERVICE_DIR/..; pwd`
	if [[ "$SERVICE_DIR" = "/" ]]; then
		echo "[ERROR] Could not find the service"
		exit 1
	fi
done

$BIN $SERVICE_DIR $*

