#!/bin/bash
set -x
set -e

# READ ENV FILE
set -o allexport
source .env$2
set +o allexport

# PROJECT_NAME = <user_id>-<current_directory_name>
PROJECT_NAME=$USER-${PWD##*/}$2

export KILT_RAW_SPEC_FILE=/data/spec/$KILT_SOURCE_SPEC-raw.json

export PARA_WASM=kilt$2.wasm
export PARA_GENESIS=kilt-genesis$2.hex
export RELAY_CHAIN_SPEC=/data/spec/${RELAY_RAW_SPEC_FILE}

# Spin it up the network and script
docker compose -p $PROJECT_NAME stop $1
docker compose -p $PROJECT_NAME rm $1
docker compose -p $PROJECT_NAME up -d $1
