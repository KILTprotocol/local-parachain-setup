# How to setup the KILT Parachain

In case you want to JSON Chainspecs for either or both the KILT parachain as well as the Polkadot relay chain, please put them into the [specs](./specs) directory.
This folder will be mounted into a volume inside the KILT docker image.

1. In the `.env`
   1. Select the [KILT image](https://hub.docker.com/r/kiltprotocol/peregrine/tags?page=1&ordering=last_updated) and the [corresponding spec](https://github.com/KILTprotocol/mashnet-node/blob/develop/nodes/parachain/src/command.rs#L41).
   * The runtime should always be `peregrine` or `spiritnet` because otherwise you would run in `standalone` which does neither require nor work with the parachain setup.
   ```
   KILT_IMG=kiltprotocol/kilt-node:develop
   KILT_RAW_SPEC_FILE=spiritnet-dev
   KILT_RUNTIME=spiritnet
   ```
   2. Select the [Polkadot image to run](https://hub.docker.com/r/parity/polkadot/tags?page=1&ordering=last_updated).
   * Typically, this should be the latest image. Please note that **if you bump the version number, you might [need to build a relay spec](#relay-spec)**.
   ```
   RELAY_IMG=parity/polkadot:v0.9.13
   RELAY_RAW_SPEC_FILE=rococo-0.9.13.raw.json
   RELAY_CHAIN_SPEC=/data/spec/${RELAY_RAW_SPEC_FILE}
   ```
   3. If you have made adjustments to the parachain id, please change it.
   * Typically, this should be `2000`.
   * If you are unsure, go to step 2 and check the parachain id in the logs or the [Polkadot Apps](https://polkadot.js.org/apps/?rpc=ws%3A%2F%2F127.0.0.1%3A9944#/extrinsics) at _Developer > Chain State > parachainInfo::parachainId_. 
   * You might have to manually re-build the `registerParachain` script in case you have built it before with the incorrect parachain ID.
   ```
   PARA_ID=2000
   RELAY_SUDO_KEY="//Alice"

   ```
2. Execute the [`run.sh`](./run.sh) script.
* It uses the [docker compose CLI](https://docs.docker.com/compose/cli-command/) aka `docker compose` not `docker-compose`.
* The genesis state and WASM are updated after running `run.sh` and can be found in [specs/kilt.wasm](specs/kilt.wasm) or [specs/kilt-genesis.hex](/specs/kilt-genesis.hex).
* It will set up 3 relay chain validator and 2 parachain collators nodes, register the parachain as a parathread, upgrade it to a parachain and increase its parachain duration (leases) to more than a year.

Once you are done, you can stop all containers by executing the [`kill.sh`](./kill.sh) script.

## Relay spec

When bumping the version number of the Polkadot relay chain image, chances are high that you need to create as new chain spec for the relay chain. 
Depending on the chain spec for the KILT collator, you either need to do this in the [Polkadot](https://github.com/paritytech/polkadot) or the [kilt-node](https://github.com/KILTprotocol/mashnet-node/tree/develop/.maintain/reset-spec) repo.
**We recommend to stick with a dev spec for simplicity.**

After building the spec, please move it inside the [specs](./specs) directory which will be mounted inside the KILT docker image.

### Dev Spec

If you are running the KILT collators in dev spec (`--runtime=spiritnet --chain=spiritnet-dev` or `--runtime=peregrine --chain=dev`), you need to build a new rococo-local spec inside the Polkadot repo
```
cargo run --release -- build-spec --chain=rococo-local --disable-default-bootnode --raw  > rococo-${POLKADOT_VERSION}.raw.json
```

### Peregrine {Stg | Prod}, WILT and Spiritnet Kusama
We do not recommend running the collators with a KILT spec of our live collators because the pre-compiled genesis specs are basically outdated by now, e.g. you might encounter issues when running the relay chain on the most recent client with an old chain spec.
Same holds true for the collators because the corresponding KILT runtime has received multiple runtime upgrades since go-live.

If you still want to proceed, have a look [here](https://github.com/KILTprotocol/mashnet-node/tree/develop/.maintain/reset-spec).

## Keys

The node keys can be found in [keys](/keys). We recommend to use the default session keys of Alice, Bob, Charlie for your collators because else you have to configure those as well.

## How to register a Parachain manually

The following steps are only required if the `registerParachain` scripts fails or if you want to add another parachain as well: 

1. Register the parachain
   * With Sudo: _Sudo > registrar > forceRegister > Submit Sudo_
   * Without Sudo: Register the parachain in the Polkadot Apps: _Network > Parachains > Parathreads -> `+ Register`_.
2. Increase parachain Duration: _Sudo > slots::forceLease_ 

61757261