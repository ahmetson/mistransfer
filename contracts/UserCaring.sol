// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./UserCaringInterface.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UserCaring is UserCaringInterface {
    address public userInterface;
    address public caringSupporter; // owner

    mapping(address => mapping(uint => bool)) public lockedNfts;
    mapping(address => mapping(address => uint)) public lockedTokens;

    modifier onlyInterfaceOrSupporter {
        require(msg.sender == userInterface || msg.sender == caringSupporter, "not_allowed");
        _;
    }

    modifier intentionalNftAdd(address nft, uint tokenId) {
        _;
        lockedNfts[nft][tokenId] = true;
    }

    modifier intentionalNftRemove(address nft, uint tokenId) {
        _;
        delete lockedNfts[nft][tokenId];
    }

    modifier intentionalTokenAdd(address token, address user, uint amount) {
        _;
        lockedTokens[token][msg.sender] += amount;
    }

    modifier intentionalTokenRemove(address token, address user, uint amount) {
        _;
        lockedTokens[token][msg.sender] -= amount;
    }

    constructor(address _userInterface) {
        userInterface = _userInterface;
        caringSupporter = msg.sender;
    }

    function recoverUserNft(address nftAddress, address to, uint tokenId) external onlyInterfaceOrSupporter {
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == address(this), "not_locked");
        require(!lockedNfts[nftAddress][tokenId], "intentionally_locked_nft");

        nft.transferFrom(msg.sender, to, tokenId);
    }

    function recoverUserToken(address token, address to, uint amount) external onlyInterfaceOrSupporter {
        IERC20 erc20 = IERC20(token);
        uint contractBalance = erc20.balanceOf(address(this));

        require(amount > lockedTokens[token][to], "intentionally_locked_nft");
        require(contractBalance >= amount + lockedTokens[token][to], "not_locked_amount");

        erc20.transfer(to, amount);
    }

    function setCaringSupporter(address newOwner) external {
        require(msg.sender == caringSupporter, "not_owner");
        caringSupporter = newOwner;
    }

}