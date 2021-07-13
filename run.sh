#!/bin/bash
set -x
set -e

# READ ENV FILE
set -o allexport
source .env
set +o allexport

# PROJECT_NAME = <user_id>-<current_directory_name>
PROJECT_NAME=$USER-${PWD##*/}
export CURRENT_UID=$(id -u):$(id -g)
# CURRENT_UID=1007:1008

# TEARDOWN AND DELETE
docker compose -p $PROJECT_NAME down -v

# Get relay chain spec, genesis wasm+head

docker run --rm $KILT_IMG export-genesis-state --chain=$KILT_RAW_SPEC_FILE --runtime=$KILT_RUNTIME > specs/kilt-genesis.hex
docker run --rm $KILT_IMG export-genesis-wasm --chain=$KILT_RAW_SPEC_FILE --runtime=$KILT_RUNTIME > specs/kilt.wasm
docker run --rm --entrypoint cat $KILT_IMG /node/dev-specs/kilt-parachain/peregrine-relay.json > specs/polkadot.raw.json

docker compose -p $PROJECT_NAME up -d