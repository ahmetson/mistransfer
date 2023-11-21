// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./Interface.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// UserInterface is where the user gets the contracts.
contract UserInterface is Interface {
    constructor() {}

    uint public fee;

    constructor() {
        fee = 10000000000000000; // 0.01 ETH as a constant fee for a demo. In the future it should be dynamic.
    }

    // Todo make sure that token id is owned by targetContract
    function recoverMyNft(bytes calldata txHash, address targetContract, address token, uint tokenId) payable external {
        IERC721 nft = IERC721(token);
        require(nft.ownerOf(tokenId) == targetContract, "not owner");

        require(msg.value >= fee, "not_enough_fee");

        // fetch the event from rpc. // to fetch from multiple RPCs maybe add a session and count.
        // validate the rpc.
        // call the recover in the target contract.
    }

    // Todo make sure that target contract has enough tokens
    function recoverMyToken(bytes calldata txHash, address targetContract, address token, uint amount) payable external {
        IERC20 erc20 = IERC20(token);
        require(erc20.balanceOf(targetContract) > amount, "not_enough");

        require(msg.value >= fee, "not_enough_fee");

        // fetch the event from rpc. // to fetch from multiple RPCs maybe add a session and count.
        // validate the rpc.
        // call the recover in the target contract.
    }

    // Todo Make add access control
    function removeUrl(string calldata url) external {}
    // Todo make add access control
    function addUrl(string calldata url) external {}
}
