// inspired from https://polkadot.js.org/docs/api/cookbook/tx#how-do-i-get-the-result-of-a-sudo-event
function checkSudoError(api, events) {
    let isSudoError;
    events
        // We know this tx should result in `Sudid` event.
        .filter(({ event }) =>
            api.events.sudo.Sudid.is(event)
        )
        // We know that `Sudid` returns just a `Result`
        .forEach(({ event: { data: [result] } }) => {
            // Now we look to see if the extrinsic was actually successful or not...
            if (result.isErr) {
                let error = result.asErr;
                if (error.isModule) {
                    // for module errors, we have the section indexed, lookup
                    const decoded = api.registry.findMetaError(error.asModule);
                    const { docs, name, section } = decoded;
                    console.error(`Sudo Transaction Error: ${section}.${name}: ${docs.join(' ')}`);
                    isSudoError = name;
                } else {
                    // Other, CannotLookup, BadOrigin, no extra info
                    console.error(`Sudo Transaction Error: ${error.toString()}`);
                    isSudoError = error.toString();
                }
            }
        });
    return isSudoError;
}

async function sudoHandler({ api, events, status, dispatchError, finalization, unsub, resolvePromise, reject }) {
    console.log(`Current status is ${status}`);
    // check for sudo error which is handled differently than dispatchError
    let isSudoError = checkSudoError(api, events);
    if (isSudoError) {
        reject(isSudoError);
    }
    else if (status.isInBlock) {
        console.log(
            `Transaction included at blockHash ${status.asInBlock}`
        );
        if (finalization) {
            console.log("Waiting for finalization...");
        } else {
            unsub();
            resolvePromise();
        }
    } else if (status.isFinalized) {
        console.log(
            `Transaction finalized at blockHash ${status.asFinalized}`
        );
        unsub();
        resolvePromise();
    } else if (dispatchError) {
        console.log(`Transaction Error:`);
        // inspired from https://polkadot.js.org/docs/api/cookbook/tx#how-do-i-get-the-decoded-enum-for-an-extrinsicfailed-event
        if (dispatchError.isModule) {
            // for module errors, we have the section indexed, lookup
            const decoded = api.registry.findMetaError(dispatchError.asModule);
            const { docs, name, section } = decoded;

            console.log(`\t ${section}.${name}: ${docs.join(' ')}`);
        } else {
            // Other, CannotLookup, BadOrigin, no extra info
            console.log(`\t ${dispatchError.toString()}`);
        }
        reject(`Transaction Error`);
    }
}

async function forceLease({ api, sudoAcc, finalization, paraId, leaser, amount, begin, count }) {
    return new Promise(async (resolvePromise, reject) => {
        console.log(
            `--- Submitting extrinsic to force lease for paraId ${paraId} ---`
        );

        const unsubForce = await api.tx.sudo
            .sudo(api.tx.slots.forceLease(paraId, leaser, amount, begin, count))
            .signAndSend(sudoAcc, ({ events = [], status, dispatchError }) =>
                sudoHandler({ events, status, dispatchError, finalization: false, unsub: unsubForce, resolvePromise, reject }))
    }).catch(async (_e) => {
        console.log(`-- Encountered Error during forceLease, clearing all leases now and forcing new onces -- 
        `);
        return new Promise(async (resolveInner, rejectInner) => {
            // clear leases
            const unsubClear = await api.tx.sudo
                .sudo(api.tx.slots.clearAllLeases(paraId))
                .signAndSend(sudoAcc, { nonce: -1 }, ({ events = [], status, dispatchError }) =>
                    sudoHandler({ events, status, dispatchError, finalization, unsub: unsubClear, resolvePromise: resolveInner, reject: rejectInner })
                );
            console.log(`Cleared parachain leases`);
            // retry forceLease
            const unsubForceAgain = await api.tx.sudo
                .sudo(api.tx.slots.forceLease(paraId, leaser, amount, begin, count))
                .signAndSend(sudoAcc, { nonce: -1 }, ({ events = [], status, dispatchError }) =>
                    sudoHandler({ events, status, dispatchError, finalization, unsub: unsubForceAgain, resolvePromise: resolveInner, reject: rejectInner })
                );
        })
    })
}

// Submit an extrinsic to the relay chain to register a parachain.
async function registerParachain({
    api,
    sudoAcc,
    paraId,
    wasm,
    genesisHead,
    finalization = false
}) {
    return new Promise(async (resolvePromise, reject) => {
        console.log(
            `--- Submitting extrinsic to register parachain ${paraId} ---`
        );
        let paraGenesisArgs = {
            genesis_head: genesisHead,
            validation_code: wasm,
            parachain: true,
        };
        const unsub = await api.tx.sudo
            .sudo(api.tx.parasSudoWrapper.sudoScheduleParaInitialize(paraId, paraGenesisArgs))
            .signAndSend(sudoAcc, ({ events = [], status, dispatchError }) =>
                sudoHandler({ api, events, status, dispatchError, finalization, unsub, resolvePromise, reject })
            );
    });
}

async function setMinParaUpgradeDelay({ api, sudoAcc, finalization = false }) {
    return new Promise(async (resolvePromise, reject) => {
        console.log(
            `--- Submitting extrinsic to reduce parachain upgrade delay to 5 blocks ---`
        );
        const unsub = await api.tx.sudo
            .sudo(api.tx.parachainsConfiguration.setValidationUpgradeDelay(5))
            .signAndSend(sudoAcc, ({ events = [], status, dispatchError }) =>
                sudoHandler({ api, events, status, dispatchError, finalization, unsub, resolvePromise, reject })
            );
    });
}

async function speedUpParaOnboarding({ api, sudoAcc, paraId, finalization = false }) {
    return new Promise(async (resolvePromise, reject) => {
        console.log(
            `--- Submitting extrinsic to putting the parachain directly into the next session's action queue ---`
        );
        const unsub = await api.tx.sudo
            .sudo(api.tx.paras.forceQueueAction(paraId))
            .signAndSend(sudoAcc, ({ events = [], status, dispatchError }) =>
                sudoHandler({ api, events, status, dispatchError, finalization, unsub, resolvePromise, reject })
            );
    });
}

module.exports.forceLease = forceLease;
module.exports.registerParachain = registerParachain;
module.exports.setMinParaUpgradeDelay = setMinParaUpgradeDelay;
module.exports.speedUpParaOnboarding = speedUpParaOnboarding;