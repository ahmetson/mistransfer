import express from "express";
import bodyParser from "body-parser";
import cors from "cors";

const app = express();
const port = process.env.PORT || 3000;
app.use(cors());

// create application/json parser
var jsonParser = bodyParser.json()

const url = `https://sepolia.infura.io/v3/5ddda5dd2d714c299b468caae630f0c6`;
const blockNumberData = {
    "jsonrpc":"2.0",
    "method":"eth_blockNumber",
    "params": [],
    "id":1
}

const transactionReceiptData = {
    "jsonrpc":"2.0",
    "method":"eth_getTransactionReceipt",
    "params": ["0x9139bb33cee7c1854037183a407e72b0c17c4f186ec1654b38cd34398432971e"],
    "id":1
}

async function fetchPost(url = "", data = {}) {
    // Default options are marked with *
    const response = await fetch(url, {
        method: "POST", // *GET, POST, PUT, DELETE, etc.
        mode: "cors", // no-cors, *cors, same-origin
        cache: "no-cache", // *default, no-cache, reload, force-cache, only-if-cached
        credentials: "same-origin", // include, *same-origin, omit
        headers: {
            "Content-Type": "application/json",
        },
        redirect: "follow", // manual, *follow, error
        referrerPolicy: "no-referrer", // no-referrer, *no-referrer-when-downgrade, origin, origin-when-cross-origin, same-origin, strict-origin, strict-origin-when-cross-origin, unsafe-url
        body: JSON.stringify(data), // body data type must match "Content-Type" header
    });
    return response.json(); // parses JSON response into native JavaScript objects
}

function parseBlockNumber(response: any): number|object {
    if (response.result == null) {
        return response;
    }

    const blockNumber = parseInt(response.result, 16);
    if (isNaN(blockNumber)) {
        return {"message": "invalid block number", block_number: response.result};
    }
    return blockNumber;
}

function parseResponse(response: any): string|object {
    if (response.result == null) {
        return response.message;
    }

    return response.result;
}

app.get('/', (req, res) => {
    res.json({"status": "OK"});
});

app.get('/block-number/', async (req, res) => {
    let response = await fetchPost(url, blockNumberData);

    let blockNumber = parseBlockNumber(response);
    if (typeof(blockNumber) != "number") {
        return res.status(500).json(blockNumber);
    }
    res.json({block_number: blockNumber});
});

app.post('/block-number/', jsonParser, async (req, res) => {
    console.log(`POST block-number`, req.body);
    let response = await fetchPost(url, req.body);

    console.log(`RESPONSE`, response);

    let blockNumber = parseBlockNumber(response);
    console.log(`Parsed block number`, blockNumber);
    if (typeof(blockNumber) != "number") {
        return res.status(500).json(blockNumber);
    }
    res.json({block_number: blockNumber});
});

app.get(`/transaction-receipt/:txHash`, async (req, res) => {
    let postData = { ...transactionReceiptData };
    postData.params[0] = req.params.txHash as string;
    console.log(`GET tx receipt params txHash: ${req.params.txHash}`);
    console.log(`GET post data:`, postData);

    let response = await fetchPost(url, postData);

    console.log(`GET response`, response);

    let result = parseResponse(response);
    if (typeof(result) != "string") {
        return res.status(500).json({message: result});
    }
    res.json({result: result});
});

app.post('/transaction-receipt/', jsonParser, async (req, res) => {
    console.log(`POST transaction-receipt`, req.body);
    let response = await fetchPost(url, req.body);

    console.log(`GET response`, response);

    let result = parseResponse(response);
    if (typeof(result) != "string") {
        return res.status(500).json({message: result});
    }
    res.json({result: result});
});

app.listen(port, () => {
    console.log(`App listening on port ${port}`)
});