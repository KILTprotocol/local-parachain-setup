
# Para to Para Test Guide

Albi adjusted the project to support two environments required to spin up two docker networks which each runs a rococo relay chain and a parachain.

* Para1 is the source. It can be anything that has sudo: E.g., a kilt-node with `peregrine dev`
* Para2 is the destination and seedling: E.g., a kilt-node with `clone dev`
* Once Para1 has built some blocks, we can take its WASM and header to Para2 and continue Para1 from there
* The `kilt-collator-bob` container runs with persistent storage, required to continue Para1 after the migration to the new relay chain
  * If something fails and you need to start over, remove the data `sudo rm -r volume/kilt-bob{1,2}/db/chains/`

## Step by step

### Prep on Rust Server

1. Checkout branch `aw-seedling` of `local-parachain-setup` and create two env files `.env{1,2}`
2. Change all ports
3. Allow all three p2p ports of Relay2 validators in firewall `sudo ufw allow $R2_P2P_PORT1`
4. Change owner to `weich` independent of who you are: `sudo chown -R weich:weich volume/* .env*`
   - In case of first-time deployments, where the `volume` folder is yet not present, this needs to be done twice: once after the deployment 1 and once after the deployment 2

### Execute

1. Run first network: `./run.sh 1`
2. On Relay 1:
   1. Transfer >= 1 ROC to Account of ParaId 2086 `5Ec4AhNtskxrg56TpEJ8zweU5h4JVUmGgxDqnoE1grqycu6q`
   2. Reserve ParaId (will be 2000) with any account: `Network > Parachains > Parathreads > ParaId > + ParaId` 
   3. Register ParaThread 2000 (could take same genesis and wasm as created by script): `Network > Parachains > Parathreads > ParaId > + ParaThread` 
   4. The registrar account of the parachain 2000 calls `registrar.swapLease(2000, 2086)`
3. On Para1
   1. Set council: `sudo.council.setMembers([Alice])`
   2. Remove strict relay block number requirement: `council > Motion > propose motion > relayMigration.disable...)`
   3. Swap ParaLease with 2000: `council > Motion > propose motion > relayMigration.send_swap_call_bytes(0x1a0326080000d0070000, 1000000000000, 10000000000)`
```
         swap call: 0x1a0326080000d0070000
         balance:   1000000000000
                      10000000000
```
4. On Relay 1: Should see Para 2086 being downgraded
5. On Para1: Get header of last block: `Developer > Javascript > console.log((await api.rpc.chain.getHeader()).toHex())`
6. Run second network: `./run.sh 2`
7. On Para2: `sudo > soloToPara.scheduleMigration(wasm from setup 1, header from 5.)`
8. Once migration is complete (Para2 stops producing block): 
   1. In [docker-compose.yml](./docker-compose.yml) `kilt-collator-alice` and `kilt-collator-bob` Comment out relay chain spec and bootnodes and uncomment similar section below. **Also change the hardcoded relay2 validator p2p ports!**
   ```
         # "--chain=${RELAY_CHAIN_SPEC}",
         # "--bootnodes",
         # "/dns4/relay-node-alice/tcp/${PORT_RELAY_ALICE_LIBP2P}/p2p/12D3KooWPU8zhfbYjr6mGuDdrrkQMFfDm2edXFYkkkmyCBont8K5",
         # "--bootnodes",
         # "/dns4/relay-node-bob/tcp/${PORT_RELAY_BOB_LIBP2P}/p2p/12D3KooWGFFpuUgFSFwNVLeVhNJ6m25jgv15pK8xcbdqaAj9gfnc",
         # "--bootnodes",
         # "/dns4/relay-node-charlie/tcp/${PORT_RELAY_CHARLIE_LIBP2P}/p2p/12D3KooWPaFM8dPrm5GodDmggNPNLrKLUzDnLYuEStVZ7sesjrrW"
         "--chain=/data/spec/rococo-0.9.27.raw2.json",
         "--bootnodes",
         "/ip4/78.46.69.208/tcp/R2_P2P_PORT_ALICE/p2p/12D3KooWPU8zhfbYjr6mGuDdrrkQMFfDm2edXFYkkkmyCBont8K5",
         "--bootnodes",
         "/ip4/78.46.69.208/tcp/R2_P2P_PORT_BOB/p2p/12D3KooWGFFpuUgFSFwNVLeVhNJ6m25jgv15pK8xcbdqaAj9gfnc",
         "--bootnodes",
         "/ip4/78.46.69.208/tcp/R2_P2P_PORT_CHARLIE/p2p/12D3KooWPaFM8dPrm5GodDmggNPNLrKLUzDnLYuEStVZ7sesjrrW"
   ```
   2. Restart bob (holds para1 data) pointing to relay2 instead of rlay1: `./update.sh kilt-collator-bob 1`
   3. Restart alice pointing to relay2 instead of relay1: `./update.sh kilt-collator-alice 1`
9. Should see new blocks being finalized on top of the head of Para1