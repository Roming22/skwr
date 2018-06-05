#!/bin/bash
SCRIPT_DIR=`cd $(dirname $(readlink -f $0)); pwd`

usage(){
echo "
Commands:
`for C in $(find $SCRIPT_DIR -name run.sh -exec dirname {} \;); do echo "  $(basename $C)"; done`

Flags:
  -h,--help	      show this message
  -v,--verbose    increase verbose level
"
}

init(){
  SCRIPT_DIR=`cd $(dirname $(readlink -f $0)); pwd`
  MODULE_DIR="$PWD"
  while [[ ! -e "$MODULE_DIR/docker" && ! -e "$MODULE_DIR/etc" ]]; do
    MODULE_DIR=`cd $MODULE_DIR/..; pwd`
    if [[ "$MODULE_DIR" = "/" ]]; then
      unset MODULE_DIR
      break
    fi
  done
}

parse_args(){
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) set -x; VERBOSE="-v" ;;
      *) COMMAND=$1; shift; break ;;
    esac
    shift
  done
}

init
parse_args $*
$SCRIPT_DIR/$COMMAND/run.sh $* $VERBOSE

