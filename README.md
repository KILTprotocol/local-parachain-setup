# How to setup Parachain

- execute the `run.sh` script
  - it uses the [docker compose CLI](https://docs.docker.com/compose/cli-command/) aka `docker compose` not `docker-compose`
- select the image to run in `.env`
- Parachain ID should be `12555`, but can be looked up at Developer > Chain State > parachainInfo::parachainId
- genesis state and wasm is updated after running `run.sh` and can be found in `specs/{kilt.wasm,kilt-genesis.hex}`
- account, node and sesssion keys can be found in `keys`
- Custom types for the polkadot-apps are in `kilt-types.json`

## register

- register parachain: Network > Parachains > Parathreads -> `+ Register`
- Sudo > slots::forceLease
