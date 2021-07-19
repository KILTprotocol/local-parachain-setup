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
docker run --rm --entrypoint cat $KILT_IMG /node/dev-specs/kilt-parachain/peregrine-stg-relay.json > specs/polkadot.raw.json

# Specs cannot be accessed from parent directories when building the docker image, thus they need to be copied
cp specs/kilt-genesis.hex scripts/registerParachain/kilt-genesis.hex
cp specs/kilt.wasm scripts/registerParachain/kilt.wasm

# Remove nodejs image in case it is not rebuilt because of cache
docker compose up --build --force-recreate
# Spin it up the network and script
docker compose -p $PROJECT_NAME up -d
