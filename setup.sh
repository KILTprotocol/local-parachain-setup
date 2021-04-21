#!/bin/bash
set -x

# READ ENV FILE
set -o allexport
source .env
set +o allexport

# SETUP CHAIN SPECS
pushd specs

## BUILD PLAIN SPECS
# docker run $ACALA_IMG build-spec --chain $ACALA_SPEC --disable-default-bootnode > acala.plain.json
docker run $KILT_IMG build-spec --chain $KILT_BASE_SPEC --disable-default-bootnode > $KILT_PLAIN_SPEC_FILE
docker run $POLKADOT_IMG build-spec --chain $POLKADOT_SPEC --raw --disable-default-bootnode > $POLKADOT_RAW_SPEC_FILE

docker run $ACALA_IMG build-spec --chain $ACALA_SPEC --disable-default-bootnode --raw > acala.raw.json

## MODIFY SPECS
jq -f --arg KILT_ID $KILT_ID ../update-kilt.jq $KILT_PLAIN_SPEC_FILE | sponge $KILT_PLAIN_SPEC_FILE

## BUILD RAW SPECS
docker run -v $PWD:/data $KILT_IMG build-spec --chain /data/$KILT_PLAIN_SPEC_FILE --disable-default-bootnode --raw > $KILT_RAW_SPEC_FILE

# SETUP PARACHAINS genesis and wasm
docker run $ACALA_IMG export-genesis-state --chain dev --parachain-id $ACALA_ID > acala-genesis.hex
docker run $ACALA_IMG export-genesis-wasm --chain dev > acala.wasm

docker run -v $PWD/:/data $KILT_IMG export-genesis-state --chain /data/$KILT_RAW_SPEC_FILE --parachain-id $KILT_ID > kilt-genesis.hex
docker run -v $PWD/:/data $KILT_IMG export-genesis-wasm --chain /data/$KILT_RAW_SPEC_FILE > kilt.wasm


popd
