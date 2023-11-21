// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./UserCaring.sol";

contract Clicker is UserCaring {
    uint public clickCounts = 0;

    event Click(address _owner, uint _clickCounts);

    constructor() UserCaring(msg.sender) {}

    /**
     * @dev Set click count
     */
    function click() external  {
        clickCounts++;
        emit Click(msg.sender, clickCounts);
    }
}