#!/bin/bash
set -x
set -e

# READ ENV FILE
set -o allexport
source .env
set +o allexport

# PROJECT_NAME = <user_id>-<current_directory_name>
PROJECT_NAME=$USER-${PWD##*/}

export KILT_RAW_SPEC_FILE=/data/spec/raw-spiritnet.json
export KILT_RUNTIME=spiritnet

# Spin it up the network and script
docker compose -p $PROJECT_NAME rm -s $1
docker compose -p $PROJECT_NAME up -d $1
