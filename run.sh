#!/bin/bash
set -x

# READ ENV FILE
set -o allexport
source .env
set +o allexport

# TEARDOWN AND DELETE
docker compose down

# BUILD PLAIN SPECS
docker run $ACALA_IMG build-spec --chain $ACALA_SPEC --disable-default-bootnode > acala.plain.json
docker run $KILT_IMG build-spec --chain $KILT_BASE_SPEC --disable-default-bootnode > $KILT_PLAIN_SPEC_FILE

# MODIFY SPECS
# jq -f update-kilt.jq $KILT_PLAIN_SPEC_FILE | sponge $KILT_PLAIN_SPEC_FILE
read -p "Press Enter to continue" </dev/tty

# BUILD RAW SPECS
# docker run $ACALA_IMG build-spec --chain $ACALA_SPEC --disable-default-bootnode > acala.plain.json
docker run -v $PWD/:/data $KILT_IMG build-spec --chain /data/$KILT_PLAIN_SPEC_FILE --disable-default-bootnode > $KILT_RAW_SPEC_FILE

docker run $POLKADOT_IMG build-spec --chain $POLKADOT_SPEC --raw --disable-default-bootnode > $POLKADOT_RAW_SPEC_FILE


# SETUP PARACHAINS
docker run $ACALA_IMG export-genesis-state --chain $ACALA_SPEC > acala-genesis.hex
docker run $ACALA_IMG export-genesis-wasm --chain $ACALA_SPEC > acala.wasm

docker run -v $PWD/:/data $KILT_IMG export-genesis-state --chain /data/$KILT_RAW_SPEC_FILE > kilt-genesis.hex
docker run -v $PWD/:/data $KILT_IMG export-genesis-wasm --chain /data/$KILT_RAW_SPEC_FILE > kilt.wasm

# COPY SPECS
cp $POLKADOT_RAW_SPEC_FILE volume/para-acala
cp $POLKADOT_RAW_SPEC_FILE volume/para-kilt
cp $POLKADOT_RAW_SPEC_FILE volume/relay

cp $KILT_RAW_SPEC_FILE volume/para-kilt
cp acala.raw.json volume/para-acala

# START
docker compose up -d
