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

export PARA_WASM=kilt$1.wasm
export PARA_GENESIS=kilt-genesis$1.hex
export RELAY_CHAIN_SPEC=/data/spec/${RELAY_RAW_SPEC_FILE}


docker compose -p $PROJECT_NAME up -d $1
