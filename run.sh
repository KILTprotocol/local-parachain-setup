#!/bin/bash
set -x

# READ ENV FILE
set -o allexport
source .env
set +o allexport

# TEARDOWN AND DELETE
docker compose down

./setup.sh

# COPY SPECS
cp $POLKADOT_RAW_SPEC_FILE volume/para-acala
cp $POLKADOT_RAW_SPEC_FILE volume/para-kilt
cp $POLKADOT_RAW_SPEC_FILE volume/relay

cp $KILT_RAW_SPEC_FILE volume/para-kilt
cp acala.raw.json volume/para-acala

# START
docker compose up -d
