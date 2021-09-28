#!/bin/bash
set -x
set -e

# READ ENV FILE
set -o allexport
source .env
set +o allexport

# PROJECT_NAME = <user_id>-<current_directory_name>
PROJECT_NAME=$USER-${PWD##*/}

# TEARDOWN AND DELETE
docker compose -p $PROJECT_NAME down -v

# Get relay chain spec, genesis wasm+head
docker run --rm $KILT_IMG export-genesis-state --chain=$KILT_RAW_SPEC_FILE --runtime=$KILT_RUNTIME > specs/kilt-genesis.hex
docker run --rm $KILT_IMG export-genesis-wasm --chain=$KILT_RAW_SPEC_FILE --runtime=$KILT_RUNTIME > specs/kilt.wasm

# Active the line below if you are using a pre-compiled relay chain spec (peregrine {stg, prod})
# Else you need to build your own relay spec in the Polkadot repository (rococo-local for dev)
# docker run --rm --entrypoint cat $KILT_IMG /node/dev-specs/kilt-parachain/peregrine-stg-relay.json > specs/${RELAY_RAW_SPEC_FILE}

# Spin it up the network and script
docker compose -p $PROJECT_NAME up -d
