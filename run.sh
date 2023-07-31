#!/bin/bash
set -x
set -e

# READ ENV FILE
set -o allexport
source .env$1
set +o allexport

# docker pull $KILT_IMG

# PROJECT_NAME = <user_id>-<current_directory_name>
PROJECT_NAME=$USER-${PWD##*/}$1

# TEARDOWN AND DELETE
docker compose -p $PROJECT_NAME down -v

docker run -v $PWD/specs:/data/spec --rm $KILT_IMG build-spec --chain=$KILT_SOURCE_SPEC >specs/$KILT_SOURCE_SPEC-k-plain.json
docker run -v $PWD/specs:/data/spec --rm $CLONE_IMG build-spec --chain=$CLONE_SOURCE_SPEC >specs/$CLONE_SOURCE_SPEC-c-plain.json

python3 ./scripts/update_para_id.py ./specs/$KILT_SOURCE_SPEC-k-plain.json $PARA_ID_KILT
python3 ./scripts/update_para_id.py ./specs/$CLONE_SOURCE_SPEC-c-plain.json $PARA_ID_CLONE

docker run -v $PWD/specs:/data/spec --rm $KILT_IMG build-spec --chain=/data/spec/$KILT_SOURCE_SPEC-k-plain.json --raw >specs/$KILT_SOURCE_SPEC-k-raw.json
docker run -v $PWD/specs:/data/spec --rm $CLONE_IMG build-spec --chain=/data/spec/$CLONE_SOURCE_SPEC-c-plain.json --raw >specs/$CLONE_SOURCE_SPEC-c-raw.json

export KILT_RAW_SPEC_FILE=/data/spec/$KILT_SOURCE_SPEC-k-raw.json
export CLONE_RAW_SPEC_FILE=/data/spec/$CLONE_SOURCE_SPEC-c-raw.json

export KILT_WASM=kilt$1.wasm
export KILT_GENESIS=kilt-genesis$1.hex

export CLONE_WASM=clone$1.wasm
export CLONE_GENESIS=clone-genesis$1.hex

# get genesis wasm+head
docker run -v $PWD/specs:/data/spec --rm $KILT_IMG export-genesis-state --chain=$KILT_RAW_SPEC_FILE >specs/$KILT_GENESIS
docker run -v $PWD/specs:/data/spec --rm $KILT_IMG export-genesis-wasm --chain=$KILT_RAW_SPEC_FILE >specs/$KILT_WASM

docker run -v $PWD/specs:/data/spec --rm $CLONE_IMG export-genesis-state --chain=$CLONE_RAW_SPEC_FILE >specs/$CLONE_GENESIS
docker run -v $PWD/specs:/data/spec --rm $CLONE_IMG export-genesis-wasm --chain=$CLONE_RAW_SPEC_FILE >specs/$CLONE_WASM

# Active the line below if you are using a pre-compiled relay chain spec (peregrine {stg, prod})
# Else you need to build your own relay spec in the Polkadot repository (rococo-local for dev)
# docker run --rm --entrypoint cat $KILT_IMG /node/dev-specs/kilt-parachain/peregrine-stg-relay.json > specs/${RELAY_RAW_SPEC_FILE}

export RELAY_CHAIN_SPEC=/data/spec/${RELAY_RAW_SPEC_FILE}

# Spin it up the network and script
docker compose -p $PROJECT_NAME up -d
