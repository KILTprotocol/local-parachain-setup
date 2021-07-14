#!/bin/bash
set -x
set -e

# READ ENV FILE
set -o allexport
source .env
set +o allexport

# PROJECT_NAME = <user_id>-<current_directory_name>
PROJECT_NAME=$USER-${PWD##*/}
export USER_ID=$(id -u $USER)

# TEARDOWN AND DELETE
docker compose -p $PROJECT_NAME down -v

# Remove old data and create folders
rm -rf ./volume/*
mkdir -p ./volume/{relay-{alice,bob,charlie},kilt-{alice,bob}}

echo "running with user id: " $USER_ID

# Get relay chain spec, genesis wasm+head
docker run --rm $KILT_IMG export-genesis-state --chain=$KILT_RAW_SPEC_FILE --runtime=$KILT_RUNTIME > specs/kilt-genesis.hex
docker run --rm $KILT_IMG export-genesis-wasm --chain=$KILT_RAW_SPEC_FILE --runtime=$KILT_RUNTIME > specs/kilt.wasm
docker run --rm --entrypoint cat $KILT_IMG $RELAY_SPEC_SOURCE > specs/polkadot.raw.json


docker compose -p $PROJECT_NAME up -d
