import fetch from 'node-fetch'

import http from 'http';
import https from 'https';

const options = {};

if (process.env.KEEPALIVE == "true") {
    const httpAgent = new http.Agent({ keepAlive: process.env.KEEPALIVE, maxSockets: Infinity });
    const httpsAgent = new https.Agent({ keepAlive: process.env.KEEPALIVE, maxSockets: Infinity });
    options.agent = (_parsedURL) => _parsedURL.protocol == 'http:' ? httpAgent : httpsAgent;
}

console.log('Start');

const URL = process?.env?.URL
const SLEEP = process?.env?.SLEEP || 500
const GROUP_SIZE = process?.env?.GROUP_SIZE || 5
const MAX_GROUPS = process?.env?.MAX_GROUPS || 2000
const ASYNC_GATE = process?.env?.ASYNC_GATE || false

console.log(`calling ${URL}`)
console.log(`expected duration`, (MAX_GROUPS/5*3)/60, 'mins')

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));


let success = 0;
let failures = 0;
let completed = 0
let requestAttempts = 0;
let groupAttempts = 0;
let errors = [];

const handleRequest = async () => {
    try {
        requestAttempts++
        const result = await fetch(URL, { ...options });
        if(result.status !== 200) {
            failures++
            errors.push(result)
            console.log(result)
        } else {
            success++
        }
    } catch (e) {
        failures++
        errors.push(e)
        console.log('\n Inbound Error: \n')
        console.dir(e, { depth: null })
        console.log('\n Manual Trace: \n')
        console.trace();
    }
    completed++
}

console.log('waiting 10 seconds for istio and network to become ready');
await sleep(10000)
const start = new Date();
do {
    groupAttempts++
    const requests = [...Array(GROUP_SIZE)].map(async () => await handleRequest())
    if(ASYNC_GATE) {
        await Promise.all(requests);
    } else{
        Promise.all(requests);
    }
    console.dir({
        success,
        failures,
        requestAttempts,
        groupAttempts,
        completed,
        inflight: requestAttempts-completed,
        outstanding: (GROUP_SIZE * MAX_GROUPS) - completed,
        rps: Math.round(requestAttempts/ ((new Date() - start)/1000))
    }, { depth: null })
    await sleep(SLEEP)
} while (completed < (MAX_GROUPS * GROUP_SIZE));


do{
    console.log('completed')
    console.log('took', (new Date() - start)/1000/60, 'mins')
    console.dir(errors, { depth: null })
    await sleep(1000000000)
} while (completed >= (MAX_GROUPS * GROUP_SIZE));