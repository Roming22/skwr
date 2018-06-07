#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

MODULE_NAME=${1}
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
[[ `basename $MODULE_NAME` = "$MODULE_NAME" && -e "$SKWR_MODULE_DIR/$MODULE_NAME" ]] && MODULE_DIR=$SKWR_MODULE_DIR/$MODULE_NAME

# Module as a path
[[ -e "$MODULE_NAME" ]] && MODULE_DIR=`find_module_root $MODULE_NAME`

echo $MODULE_DIR
