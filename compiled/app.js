"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const body_parser_1 = __importDefault(require("body-parser"));
const cors_1 = __importDefault(require("cors"));
const app = (0, express_1.default)();
const port = process.env.PORT || 3000;
app.use((0, cors_1.default)());
// create application/json parser
var jsonParser = body_parser_1.default.json();
const url = `https://sepolia.infura.io/v3/5ddda5dd2d714c299b468caae630f0c6`;
const blockNumberData = {
    "jsonrpc": "2.0",
    "method": "eth_blockNumber",
    "params": [],
    "id": 1
};
const transactionReceiptData = {
    "jsonrpc": "2.0",
    "method": "eth_getTransactionReceipt",
    "params": ["0x9139bb33cee7c1854037183a407e72b0c17c4f186ec1654b38cd34398432971e"],
    "id": 1
};
function fetchPost(url = "", data = {}) {
    return __awaiter(this, void 0, void 0, function* () {
        // Default options are marked with *
        const response = yield fetch(url, {
            method: "POST",
            mode: "cors",
            cache: "no-cache",
            credentials: "same-origin",
            headers: {
                "Content-Type": "application/json",
            },
            redirect: "follow",
            referrerPolicy: "no-referrer",
            body: JSON.stringify(data), // body data type must match "Content-Type" header
        });
        return response.json(); // parses JSON response into native JavaScript objects
    });
}
function parseBlockNumber(response) {
    if (response.result == null) {
        return response;
    }
    const blockNumber = parseInt(response.result, 16);
    if (isNaN(blockNumber)) {
        return { "message": "invalid block number", block_number: response.result };
    }
    return blockNumber;
}
function parseResponse(response) {
    if (response.result == null) {
        return response.message;
    }
    return response.result;
}
app.get('/', (req, res) => {
    res.json({ "status": "OK" });
});
app.get('/block-number/', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    let response = yield fetchPost(url, blockNumberData);
    let blockNumber = parseBlockNumber(response);
    if (typeof (blockNumber) != "number") {
        return res.status(500).json(blockNumber);
    }
    res.json({ block_number: blockNumber });
}));
app.post('/block-number/', jsonParser, (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    console.log(`POST block-number`, req.body);
    let response = yield fetchPost(url, req.body);
    console.log(`RESPONSE`, response);
    let blockNumber = parseBlockNumber(response);
    console.log(`Parsed block number`, blockNumber);
    if (typeof (blockNumber) != "number") {
        return res.status(500).json(blockNumber);
    }
    res.json({ block_number: blockNumber });
}));
app.get(`/transaction-receipt/:txHash`, (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    let postData = Object.assign({}, transactionReceiptData);
    postData.params[0] = req.params.txHash;
    console.log(`GET tx receipt params txHash: ${req.params.txHash}`);
    console.log(`GET post data:`, postData);
    let response = yield fetchPost(url, postData);
    console.log(`GET response`, response);
    let result = parseResponse(response);
    if (typeof (result) == "string") {
        return res.status(500).json({ message: result });
    }
    res.json({ result: result });
}));
app.post('/transaction-receipt/', jsonParser, (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    console.log(`POST transaction-receipt`, req.body);
    let response = yield fetchPost(url, req.body);
    console.log(`GET response`, response);
    let result = parseResponse(response);
    if (typeof (result) == "string") {
        return res.status(500).json({ message: result });
    }
    res.json({ result: result });
}));
app.listen(port, () => {
    console.log(`App listening on port ${port}`);
});
//# sourceMappingURL=app.js.map