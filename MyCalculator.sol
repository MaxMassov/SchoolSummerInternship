// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


contract Calculator {

    function sum(int256 a, int256 b) public payable returns (int256) {
        require(msg.value== 1 ether, "I need more money!!!");
        return a + b;
    }

    function sub(int256 a, int256 b) public payable returns (int256) {
        require(msg.value == 2 ether, "I need more money!!!");
        return a - b;
    }
}