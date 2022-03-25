const path = require('path');
const { Keyring, ApiPromise, WsProvider } = require('@polkadot/api');
const { cryptoWaitReady } = require('@polkadot/util-crypto');
const { setMinParaUpgradeDelay, registerParachain, forceLease, speedUpParaOnboarding } = require('./extrinsics');
const { readFileFromPath } = require('./readFile');

const wasmPath = path.join('/wasm', 'kilt.wasm');
const genesisPath = path.join('/wasm', 'kilt-genesis.hex');
const relayProvider = process.env.RELAY_WS_ENDPOINT || 'ws://127.0.0.1:9944'
const paraId = process.env.PARA_ID || 2000;
const sudoHex = process.env.RELAY_SUDO;
const forceLeaseData = {
    // 1000 relay tokens
    amount: 1_000_000_000_000_000,
    begin: 0,
    // lease will stay alive for 365 days
    count: 365,
}

// Connect to a local Substrate node. This function wont resolve until connected.
async function connect(ws, types) {
    const provider = new WsProvider(ws);
    const api = await ApiPromise.create({
        provider,
        types,
        throwOnConnect: false,
    });
    return api;
}

// Wait for crypto to be ready and set up an account from its private key.
async function initAccount(privKey) {
    await cryptoWaitReady();

    const keyring = new Keyring({ type: "sr25519" });
    return keyring.addFromUri(privKey);
}

// Connect to chain, do transactions and disconnect.
async function main() {
    const wasm = (await readFileFromPath(wasmPath)).toString();
    const genesisHead = (await readFileFromPath(genesisPath)).toString();
    const sudoAcc = await initAccount(sudoHex);

    if (wasm.length && genesisHead.length) {
        try {
            console.log(`--- Connecting to WS provider ${relayProvider} ---`);
            let relayChainApi = await connect(
                relayProvider,
                {}
            );
            // reduce parachain runtime upgrade delay to 5 blocks
            // await setMinParaUpgradeDelay({ api: relayChainApi, sudoAcc, finalization: false });
            // register parathread and immediately make it a parachain
            await registerParachain({ api: relayChainApi, sudoAcc, paraId, wasm, genesisHead, finalization: true });
            // force lease from period 0 to period 365 for sudoAcc with balance 1000
            await forceLease({ api: relayChainApi, finalization: true, sudoAcc, leaser: sudoAcc.address, paraId, ...forceLeaseData });
            // speed up onboarding process by forcedly putting parachain directly into the next session
            // unfortunately, we cannot trigger new sessions via an extrinsic 🥶
            await speedUpParaOnboarding({ api: relayChainApi, sudoAcc, paraId, finalization: true });

            await relayChainApi.disconnect();
            console.log(`--- Done! Disconnected from WS provider ${relayProvider} ---`);
        } catch (e) {
            throw Error(e)
        }
    } else {
        console.error(wasm ? `Genesis head missing` : `Wasm missing`);
    }
}

// execution
main()