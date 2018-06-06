#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

NAME=$1
SKWR_MODULE_DIR=`cd $SCRIPT_DIR/../../modules; pwd`

find_module_root(){
	cd $1
	while [[ ! -e "$PWD/etc/service.cfg" ]]; do
    	cd ..
		[[ "$PWD" = "/" ]] && exit 1
	done
	echo $PWD
}

# Registered module
[[ `basename $NAME` = "$NAME" && -e "$SKWR_MODULE_DIR/$NAME" ]] && MODULE_DIR=$SKWR_MODULE_DIR/$NAME

# Module as a path
[[ -e "$NAME" ]] && MODULE_DIR=`find_module_root $NAME`

echo $MODULE_DIR
