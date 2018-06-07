#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`
echo "NAME: STATUS (IMAGE)"
docker ps --format "{{.Names}}: {{.Status}} ({{.Image}})" | sort
