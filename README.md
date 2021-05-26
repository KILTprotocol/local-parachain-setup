# How to setup the KILT Parachain

1. Execute the `run.sh` script.
It uses the [docker compose CLI](https://docs.docker.com/compose/cli-command/) aka `docker compose` not `docker-compose`.
2. Select the image to run in `.env`.
3. The Parachain ID should be `12555`. It can be looked up at _Developer > Chain State > parachainInfo::parachainId_.
4. The genesis state and WASM are updated after running `run.sh` and can be found in [specs/kilt.wasm](specs/kilt.wasm) or [specs/kilt-genesis.hex](/specs/kilt-genesis.hex).

## Keys

Account, node and session keys can be found in [keys](/keys).
## Custom Types

Custom types for the polkadot-apps are in [kilt-types.json](./kilt-types.json)

## How to register a Parachain

1. Register the parachain in the Polkadot Apps: _Network > Parachains > Parathreads -> `+ Register`_.
2. _Sudo > slots::forceLease_ 
