function findSudoError(events) {
    let sudoError;
    events.forEach((record) => {
        const { event } = record;
        const types = event.typeDef;
        if (event.method === 'Sudid') {
            return event.data.forEach((data, index) => {
                if (types[index].type == 'DispatchResult' && data.isError) {
                    sudoError = data.toJSON().err.module;
                }
            });
        }
    });
    return sudoError;
}

function findErrorInMeta(metadata, { index: moduleIndex, error: errorIndex }) {
    const { modules } = metadata;

    if (modules[moduleIndex].errors[errorIndex]) {
        console.log(modules[moduleIndex].errors[errorIndex])
        return modules[moduleIndex].errors[errorIndex];
    } else {
        console.error(`Couldn't find module ${moduleIndex} and ${errorIndex} in metadata`);
    }
}

async function sudoHandler({ events, status, isError, metadata, finalization, unsub, resolvePromise, reject }) {
    console.log(`Current status is ${status}`);
    let sudoError = findSudoError(events);

    if (sudoError) {
        const { name, documentation } = findErrorInMeta(metadata, sudoError);
        console.error(`Sudo Transaction Error: ${name}`);
        console.error(`\t${documentation}`);
        reject(name)
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
    } else if (isError) {
        console.log(`Transaction Error`);
        reject(`Transaction Error`);
    }
}

async function forceLease({ api, sudoAcc, metadata, finalization, paraId, leaser, amount, begin, count }) {
    return new Promise(async (resolvePromise, reject) => {
        console.log(
            `--- Submitting extrinsic to force lease for paraId ${paraId} ---`
        );

        const unsubForce = await api.tx.sudo
            .sudo(api.tx.slots.forceLease(paraId, leaser, amount, begin, count))
            .signAndSend(sudoAcc, ({ events = [], status, isError }) =>
                sudoHandler({ events, status, isError, metadata, finalization: false, unsub: unsubForce, resolvePromise, reject }))
    }).catch(async (e) => {
        console.log(`-- Encountered Error during forceLease, clearing all leases now and forcing new onces -- 
        `);
        return new Promise(async (resolveInner, rejectInner) => {
            // clear leases
            const unsubClear = await api.tx.sudo
                .sudo(api.tx.slots.clearAllLeases(paraId))
                .signAndSend(sudoAcc, { nonce: -1 }, ({ events = [], status, isError }) =>
                    sudoHandler({ events, status, isError, metadata, finalization, unsub: unsubClear, resolvePromise: resolveInner, reject: rejectInner })
                );
            console.log(`Cleared parachain leases`);
            // retry forceLease
            const unsubForceAgain = await api.tx.sudo
                .sudo(api.tx.slots.forceLease(paraId, leaser, amount, begin, count))
                .signAndSend(sudoAcc, { nonce: -1 }, ({ events = [], status, isError }) =>
                    sudoHandler({ events, status, isError, metadata, finalization, unsub: unsubForceAgain, resolvePromise: resolveInner, reject: rejectInner })
                );
        })
    })
}

// Submit an extrinsic to the relay chain to register a parachain.
async function registerParachain({
    api,
    metadata,
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
            .signAndSend(sudoAcc, ({ events = [], status, isError }) =>
                sudoHandler({ events, status, isError, metadata, finalization, unsub, resolvePromise, reject })
            );
    });
}

async function setMinParaUpgradeDelay({ api, sudoAcc, metadata, finalization = false }) {
    return new Promise(async (resolvePromise, reject) => {
        console.log(
            `--- Submitting extrinsic to reduce parachain upgrade delay to 5 blocks ---`
        );
        const unsub = await api.tx.sudo
            .sudo(api.tx.parachainsConfiguration.setValidationUpgradeDelay(5))
            .signAndSend(sudoAcc, ({ events = [], status, isError }) =>
                sudoHandler({ events, status, isError, metadata, finalization, unsub, resolvePromise, reject })
            );
    });
}

async function speedUpParaOnboarding ({ api, sudoAcc, paraId, metadata, finalization = false}) {
    return new Promise(async (resolvePromise, reject) => {
        console.log(
            `--- Submitting extrinsic to putting the parachain directly into the next session's action queue ---`
        );
        const unsub = await api.tx.sudo
            .sudo(api.tx.paras.forceQueueAction(paraId))
            .signAndSend(sudoAcc, ({ events = [], status, isError }) =>
                sudoHandler({ events, status, isError, metadata, finalization, unsub, resolvePromise, reject })
            );
    });
}

module.exports.forceLease = forceLease;
module.exports.registerParachain = registerParachain;
module.exports.setMinParaUpgradeDelay = setMinParaUpgradeDelay;
module.exports.speedUpParaOnboarding = speedUpParaOnboarding;