const txHash = args[0].toLowerCase();
const user = args[1].toLowerCase();
const targetContract = args[2].toLowerCase();
const token = args[3].toLowerCase();
const amount = parseInt(args[4]);
const url = args[5];

const apiResponse = await Functions.makeHttpRequest({
    url: url,
    method: 'POST',
    data: JSON.stringify({
        jsonrpc: '2.0',
        method: 'eth_getTransactionReceipt',
        params: [txHash],
        id:1
    })
})

if (apiResponse.error) {
    console.error(apiResponse.error)
    throw Error('Request failed')
}

const { data } = apiResponse;

if (data.result == null) {
    throw Error('Null returned');
}

let topic = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';

let txStatus = 0;
if (typeof(data.result.status) == 'string') {
    txStatus = parseInt(data.result.status, 16);
} else {
    txStatus = data.result.status + 0;
}
if (txStatus != 1) {
    throw Error('Tx unsuccessful');
}

if (data.result.from.toLowerCase() != user) {
    throw Error('Transaction caller is invalid');
}
if (data.result.logs.length == 0) {
    throw Error(`No logs were recorded`);
}

let validLog = false;
for (let i = 0; i < data.result.logs.length; i++) {
    let event = data.result.logs[i];
    if (event.address.toLowerCase() != token) {
        console.log('not a token');
        continue;
    }
    if (event.topics.length < 3) {
        console.log(`no topic`);
        continue;
    }
    if (event.topics[0].toLowerCase() != topic) {
        console.log(`invalid topic`);
        continue;
    }

    if (event.topics[1].substr(66-40).toLowerCase() != user.substr(2)) {
        console.log(`from mismatch ${event.topics[1].substr(66-40).toLowerCase()} != ${user}`);
        continue;
    }

    if (event.topics[2].substr(66-40).toLowerCase() != targetContract.substr(2)) {
        console.log(`to mismatch ${event.topics[2].substr(66-40).toLowerCase()} != '${targetContract.substr(0)}'`);
        continue;
    }

    let topicAmount = 0;
    if (event.topics.length > 3) {
        topicAmount = parseInt(event.topics[3], 16);
    } else {
        topicAmount = parseInt(event.data, 16);
    }
    if (topicAmount != amount) {
        console.log(`token amount mismatch`);
        continue;
    }

    validLog = true;
    break;
}

if (!validLog) {
    throw Error('No valid logs were found');
}

let blockNumber = 0;
if (typeof(data.result.blockNumber) == 'string') {
    blockNumber = parseInt(data.result.blockNumber, 16);
} else {
    blockNumber = 0 + data.result.blockNumber;
}

return Functions.encodeUint256(blockNumber)
