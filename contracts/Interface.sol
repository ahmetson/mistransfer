// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface Interface {
    function recoverMyNft(bytes calldata txHash, address targetContract, address token, uint tokenId) payable external;
    function recoverMyToken(bytes calldata txHash, address targetContract, address token, uint amount) payable external;
    function removeUrl(string calldata url) external;
    function addUrl(string calldata url) external;
}