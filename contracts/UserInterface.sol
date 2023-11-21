// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./Interface.sol";
import "./UserCaringInterface.sol";
import "./Sources.sol";
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
    }

    struct TokenParams {
        address caller;
        address targetContract;
        address token;
        uint amount;
    }

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

    error UnexpectedRequestID(bytes32 requestId);

    event Response(address indexed caller, bytes32 indexed requestId, bytes response, bytes err);

    constructor(address _router, uint64 _subId, bytes32 _donId, string memory _url) FunctionsClient(_router) {
        // for sepolia 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0. See the
        // https://docs.chain.link/chainlink-functions/supported-networks
        chainLinkRouter = _router;
        // Sub ID: 1705. Obtained at https://functions.chain.link/sepolia/new
        // To obtain the subscription id create an account on the platform.
        // Make sure to add UserInterface as the consumer.
        chainLinkSubId = _subId;
        // For sepolia: 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000
        chainLinkDonId = _donId;

        fee = 10000000000000000;

        addUrl(_url);
    }

    // https://www.appsloveworld.com/ethereum/32/convert-bytes-to-hexadecimal-string-in-solidity
    function iToHex(bytes memory buffer) public pure returns (string memory) {
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }

    // Todo make sure that token id is owned by targetContract
    function recoverMyNft(bytes calldata txHash, address targetContract, address token, uint tokenId) payable external {
        IERC721 nft = IERC721(token);
        require(nft.ownerOf(tokenId) == targetContract, "not owner");

        require(msg.value >= fee, "not_enough_fee");
        require(targetContract.code.length > 0, "target not deployed");
        require(requests[msg.sender] == 0, "request pending");

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(Sources.nftSource); // Initialize the request with JS code
        string[] memory args = new string[](6);
        args[0] = iToHex(txHash); // transaction hash
        args[1] = Strings.toHexString(msg.sender); // user
        args[2] = Strings.toHexString(targetContract); // contract
        args[3] = Strings.toHexString(token); // token
        args[4] = Strings.toString(tokenId); // token id
        args[5] = url; // rpc url;
        req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        requests[msg.sender] = _sendRequest(
            req.encodeCBOR(),
            chainLinkSubId,
            gasLimit,
            chainLinkDonId
        );

        recoverNftParams[requests[msg.sender]] = NftParams(msg.sender, targetContract, token, tokenId);
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
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
            delete recoverNftParams[requestId];
        } else {
            userCaring.recoverUserToken(token, caller, recoverTokenParams[requestId].amount);
            delete recoverTokenParams[requestId];
        }

        payable(userCaring.caringSupporter()).transfer(fee);

        delete requests[caller];
    }

    // Todo make sure that target contract has enough tokens
    function recoverMyToken(bytes calldata txHash, address targetContract, address token, uint amount) payable external {
        IERC20 erc20 = IERC20(token);
        require(erc20.balanceOf(targetContract) > amount, "not_enough");

        require(msg.value >= fee, "not_enough_fee");

        require(targetContract.code.length > 0, "target not deployed");
        require(requests[msg.sender] == 0, "request pending");

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(Sources.tokenSource); // Initialize the request with JS code
        string[] memory args = new string[](6);
        args[0] = iToHex(txHash); // transaction hash
        args[1] = Strings.toHexString(msg.sender); // user
        args[2] = Strings.toHexString(targetContract); // contract
        args[3] = Strings.toHexString(token); // token
        args[4] = Strings.toString(amount); // token id
        args[5] = url; // rpc url;
        req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        requests[msg.sender] = _sendRequest(
            req.encodeCBOR(),
            chainLinkSubId,
            gasLimit,
            chainLinkDonId
        );

        recoverTokenParams[requests[msg.sender]] = TokenParams(msg.sender, targetContract, token, amount);
    }

    // Todo Make add access control
    function removeUrl(string calldata _url) public {

    }

    // Todo make add access control
    function addUrl(string memory _url) public {
        url = _url;
    }
}
