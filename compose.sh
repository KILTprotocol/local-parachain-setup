#!/bin/bash
set -e

# READ ENV FILE
set -o allexport
source .env$1
set +o allexport

# docker pull $KILT_IMG

# PROJECT_NAME = <user_id>-<current_directory_name>
PROJECT_NAME=$USER-${PWD##*/}$1

export KILT_RAW_SPEC_FILE=/data/spec/$KILT_SOURCE_SPEC-raw.json

export KILT_RAW_SPEC_FILE=/data/spec/$KILT_SOURCE_SPEC-k-raw.json
export CLONE_RAW_SPEC_FILE=/data/spec/$CLONE_SOURCE_SPEC-c-raw.json

export KILT_WASM=kilt$1.wasm
export KILT_GENESIS=kilt-genesis$1.hex

export CLONE_WASM=clone$1.wasm
export CLONE_GENESIS=clone-genesis$1.hex

# Active the line below if you are using a pre-compiled relay chain spec (peregrine {stg, prod})
# Else you need to build your own relay spec in the Polkadot repository (rococo-local for dev)
# docker run --rm --entrypoint cat $KILT_IMG /node/dev-specs/kilt-parachain/peregrine-stg-relay.json > specs/${RELAY_RAW_SPEC_FILE}

export RELAY_CHAIN_SPEC=/data/spec/${RELAY_RAW_SPEC_FILE}

# Spin it up the network and script
docker compose -p $PROJECT_NAME "${@:2}"r
