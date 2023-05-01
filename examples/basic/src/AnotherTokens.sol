// SPDX-License-Identifier: AGPL-1.0
pragma solidity ^0.8.13;

contract AnotherTokens {
    constructor(address to, uint256 amount) {}

    string public constant symbol = "ANOTHER_TOKENS_4";
}


struct MyStruct {
    uint256 test;
    bytes str;
}

contract AnotherTokens3 {
    constructor(address payable to, uint256 amount) {}

    string public constant symbol = "ANOTHER_TOKENS_2";
}

contract AnotherTokens4 {
    constructor(address to, uint256 amount) {}

    string public constant symbol = "ANOTHER_TOKENS_2";
}
