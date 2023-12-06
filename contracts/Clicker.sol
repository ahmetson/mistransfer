// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./UserCaring.sol";

// Example user caring smartcontract
contract Clicker is UserCaring {
    uint public clickCounts = 0;

    event Click(address _owner, uint _clickCounts);

    constructor() UserCaring(0x78220f1C11D91f9B5F21536125201bD1aE5CC676) {}

    /**
     * @dev Set click count
     */
    function click() external  {
        clickCounts++;
        emit Click(msg.sender, clickCounts);
    }
}