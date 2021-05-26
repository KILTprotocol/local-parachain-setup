#!/bin/bash
set -x

# READ ENV FILE
set -o allexport
source .env
set +o allexport

# TEARDOWN AND DELETE
docker compose down

# Get relay chain spec, genesis wasm+head

docker run $KILT_IMG export-genesis-state --chain=/node/dev-specs/kilt-parachain/peregrine-kilt.json --runtime=spiritnet > specs/kilt-genesis.hex
docker run $KILT_IMG export-genesis-wasm --chain=/node/dev-specs/kilt-parachain/peregrine-kilt.json --runtime=spiritnet > specs/kilt.wasm
docker run --entrypoint cat $KILT_IMG /node/dev-specs/kilt-parachain/peregrine-relay.json > specs/polkadot.raw.json

docker compose up -d
