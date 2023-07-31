#!/bin/bash
set -x
set -e

# READ ENV FILE
set -o allexport
source .env$2
set +o allexport

# PROJECT_NAME = <user_id>-<current_directory_name>
PROJECT_NAME=$USER-${PWD##*/}$2

export KILT_RAW_SPEC_FILE=/data/spec/$KILT_SOURCE_SPEC-k-raw.json
export CLONE_RAW_SPEC_FILE=/data/spec/$CLONE_SOURCE_SPEC-c-raw.json

export KILT_WASM=kilt$1.wasm
export KILT_GENESIS=kilt-genesis$1.hex

export CLONE_WASM=clone$1.wasm
export CLONE_GENESIS=clone-genesis$1.hex

export RELAY_CHAIN_SPEC=/data/spec/${RELAY_RAW_SPEC_FILE}

docker compose -p $PROJECT_NAME stop $1
docker compose -p $PROJECT_NAME rm $1
docker compose -p $PROJECT_NAME up -d $1
