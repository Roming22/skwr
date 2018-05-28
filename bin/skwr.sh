#!/bin/bash
SCRIPT_DIR=`cd $(dirname $(readlink -f $0)); pwd`
COMMAND=$1
shift

MODULE_DIR="$PWD"
while [[ ! -e "$MODULE_DIR/docker" && ! -e "$MODULE_DIR/etc" ]]; do
	MODULE_DIR=`cd $MODULE_DIR/..; pwd`
	if [[ "$MODULE_DIR" = "/" ]]; then
		unset MODULE_DIR
		break
	fi
done

while [[ "$#" -gt 0 ]]; do
	case $1 in
		-v) set -x; VERBOSE="-v" ;;
		*)	[[ -d "$SCRIPT_DIR/../modules/$1" ]] && MODULE_DIR="$SCRIPT_DIR/../modules/$1"
			[[ -d "$PWD/$1" ]] && MODULE_DIR=`cd $1; pwd`
			
	esac
	shift
done

if [[ -z "$MODULE_DIR" ]]; then
	echo "[ERROR] No module specified"
	echo "Known modules: `find ../modules -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | paste -sd "," - | sed 's:,:, :g'`"
	exit 1
fi

$SCRIPT_DIR/$COMMAND/run.sh $MODULE_DIR $VERBOSE

