#!/bin/bash
set -x
set -e

# READ ENV FILE
set -o allexport
source .env
set +o allexport

# TEARDOWN AND DELETE
docker compose down -v

# Get relay chain spec, genesis wasm+head

docker run $KILT_IMG export-genesis-state --chain=$KILT_RAW_SPEC_FILE --runtime=$KILT_RUNTIME > specs/kilt-genesis.hex
docker run $KILT_IMG export-genesis-wasm --chain=$KILT_RAW_SPEC_FILE --runtime=$KILT_RUNTIME > specs/kilt.wasm
docker run --entrypoint cat $KILT_IMG /node/dev-specs/kilt-parachain/westend-relay.json > specs/polkadot.raw.json

docker compose up -d
