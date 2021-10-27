# How to setup the KILT Parachain

1. In the `.env`
   1. Select the [KILT image](https://hub.docker.com/r/kiltprotocol/peregrine/tags?page=1&ordering=last_updated) and the [corresponding spec](https://github.com/KILTprotocol/mashnet-node/blob/develop/nodes/parachain/src/command.rs#L41). The runtime should always be `peregrine` because otherwise you would run in `standalone` which does neither require nor work with the parachain setup.
   ```
    KILT_IMG=kiltprotocol/kilt-node:78342538
    KILT_RAW_SPEC_FILE=dev
   ```
   2. Select the [Polkadot image to run](https://hub.docker.com/r/parity/polkadot/tags?page=1&ordering=last_updated). Typically, this should be the latest image.
   3. If you have made adjustments to the parachain id, please change it. Typically, this should be `2000`. If you are unsure, go to step 2 and check the parachain id in the logs or the [Polkadot Apps](https://polkadot.js.org/apps/?rpc=ws%3A%2F%2F127.0.0.1%3A9944#/extrinsics) at _Developer > Chain State > parachainInfo::parachainId_. 
2. Execute the [`run.sh`](./run.sh) script.
* It uses the [docker compose CLI](https://docs.docker.com/compose/cli-command/) aka `docker compose` not `docker-compose`.
* The genesis state and WASM are updated after running `run.sh` and can be found in [specs/kilt.wasm](specs/kilt.wasm) or [specs/kilt-genesis.hex](/specs/kilt-genesis.hex).
* It will set up 3 relay chain validator and 2 parachain collators nodes, register the parachain as a parathread, upgrade it to a parachain and increase its parachain duration (leases) to more than a year.

Once you are done, you can stop all containers by executing the [`kill.sh`](./kill.sh) script.

## Keys

Account, node and session keys can be found in [keys](/keys).
## Custom Types

Custom types for the polkadot-apps are in [kilt-types.json](./kilt-types.json)

## How to register a Parachain manually

The following steps are only required if the `registerParachain` scripts fails or if you want to add another parachain as well: 

1. Register the parachain
   * With Sudo: _Sudo > registrar > forceRegister > Submit Sudo_
   * Without Sudo: Register the parachain in the Polkadot Apps: _Network > Parachains > Parathreads -> `+ Register`_.
2. Increase parachain Duration: _Sudo > slots::forceLease_ 
