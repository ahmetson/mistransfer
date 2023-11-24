// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./Interface.sol";
import "./UserCaringInterface.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// UserInterface is where the user gets the contracts.
contract UserInterface is Interface, FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    struct NftParams {
        address caller;
        address targetContract;
        address token;
        uint tokenId;
        bytes32 txHash;
    }

    struct TokenParams {
        address caller;
        address targetContract;
        address token;
        uint amount;
        bytes32 txHash;
    }

    address public owner;
    address public chainLinkRouter;
    uint64 public chainLinkSubId;
    bytes32 public chainLinkDonId;
    uint32 public gasLimit = 300000;
    string public url = "";

    // Users pay this fixed fee.
    // 0.01 ETH as a constant fee for a demo. In the future it should be dynamic.
    uint public fee;

    // keep track of the statuses
    mapping(address => bytes32) public requests;
    mapping(bytes32 => NftParams) public recoverNftParams;
    mapping(bytes32 => TokenParams) public recoverTokenParams;
    mapping(bytes32 => mapping(address => bool)) public recoveredNfts;
    mapping(bytes32 => mapping(address => bool)) public recoveredTokens;

    string public tokenSource = "";
    string public nftSource = "";

    error UnexpectedRequestID(bytes32 requestId);

    event Response(address indexed caller, bytes32 indexed requestId, bytes response, bytes err);

    constructor(address _router, uint64 _subId, bytes32 _donId) FunctionsClient(_router) {
        // for sepolia 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0. See the
        // https://docs.chain.link/chainlink-functions/supported-networks
        chainLinkRouter = _router;
        // Sub ID: 1705. Obtained at https://functions.chain.link/sepolia/new
        // To obtain the subscription id create an account on the platform.
        // Make sure to add UserInterface as the consumer.
        chainLinkSubId = _subId;
        // For sepolia: 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000
        chainLinkDonId = _donId;

        owner = msg.sender;
        fee = 10000000000000000;
    }

    function setTokenSource(string calldata _source) external {
        tokenSource = _source;
    }

    function setNftSource(string calldata _source) external {
        nftSource = _source;
    }

    // https://www.appsloveworld.com/ethereum/32/convert-bytes-to-hexadecimal-string-in-solidity
    function iToHex(bytes32 buffer) public pure returns (string memory) {
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(64 * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }

    function recoverMyNft(bytes32 txHash, address targetContract, address token, uint tokenId) payable external {
        IERC721 nft = IERC721(token);
        require(nft.ownerOf(tokenId) == targetContract, "not owner");

        require(msg.value >= fee, "not_enough_fee");
        require(targetContract.code.length > 0, "target not deployed");
        require(requests[msg.sender] == 0, "request pending");
        require(!recoveredNfts[txHash][msg.sender], "already_claimed");

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(nftSource); // Initialize the request with JS code
        string[] memory args = new string[](5);
        args[0] = iToHex(txHash); // transaction hash
        args[1] = Strings.toHexString(msg.sender); // user
        args[2] = Strings.toHexString(targetContract); // contract
        args[3] = Strings.toHexString(token); // token
        args[4] = Strings.toString(tokenId); // token id
        req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        requests[msg.sender] = _sendRequest(
            req.encodeCBOR(),
            chainLinkSubId,
            gasLimit,
            chainLinkDonId
        );

        recoverNftParams[requests[msg.sender]] = NftParams(msg.sender, targetContract, token, tokenId, txHash);
    }

    function recoverMyToken(bytes32 txHash, address targetContract, address token, uint amount) payable external {
        IERC20 erc20 = IERC20(token);
        require(erc20.balanceOf(targetContract) >= amount, "not_enough");

        require(msg.value >= fee, "not_enough_fee");

        require(targetContract.code.length > 0, "target not deployed");
        require(requests[msg.sender] == 0, "request pending");
        require(!recoveredTokens[txHash][msg.sender], "already_claimed");

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(tokenSource); // Initialize the request with JS code
        string[] memory args = new string[](5);
        args[0] = iToHex(txHash); // transaction hash
        args[1] = Strings.toHexString(msg.sender); // user
        args[2] = Strings.toHexString(targetContract); // contract
        args[3] = Strings.toHexString(token); // token
        args[4] = Strings.toString(amount); // token id
        req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        requests[msg.sender] = _sendRequest(
            req.encodeCBOR(),
            chainLinkSubId,
            gasLimit,
            chainLinkDonId
        );

        recoverTokenParams[requests[msg.sender]] = TokenParams(msg.sender, targetContract, token, amount, txHash);
    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (recoverNftParams[requestId].caller == address(0) &&
            recoverTokenParams[requestId].caller == address(0)) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }

        bool nft = recoverNftParams[requestId].caller != address(0);
        address caller = nft ? recoverNftParams[requestId].caller : recoverTokenParams[requestId].caller;

        emit Response(caller, requestId, response, err);

        if (err.length > 0) {
            delete requests[caller];
            if (nft) {
                delete recoverNftParams[requestId];
            } else {
                delete recoverTokenParams[requestId];
            }
            return;
        }

        address targetContract = nft ? recoverNftParams[requestId].targetContract : recoverTokenParams[requestId].targetContract;
        address token = nft ? recoverNftParams[requestId].token : recoverTokenParams[requestId].token;

        UserCaringInterface userCaring = UserCaringInterface(targetContract);
        if (nft) {
            userCaring.recoverUserNft(token, caller, recoverNftParams[requestId].tokenId);
            recoveredNfts[recoverNftParams[requestId].txHash][recoverNftParams[requestId].caller] = true;

            delete recoverNftParams[requestId];
        } else {
            userCaring.recoverUserToken(token, caller, recoverTokenParams[requestId].amount);
            recoveredTokens[recoverTokenParams[requestId].txHash][recoverTokenParams[requestId].caller] = true;

            delete recoverTokenParams[requestId];
        }

        payable(userCaring.caringSupporter()).transfer(fee);

        delete requests[caller];
    }

    // Todo Make add access control
    function removeUrl(string calldata) public {
        url = "";
    }

    // Todo make add access control
    function addUrl(string memory _url) public {
        url = _url;
    }

    // for test only
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}
