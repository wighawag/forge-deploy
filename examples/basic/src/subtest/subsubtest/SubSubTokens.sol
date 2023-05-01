// SPDX-License-Identifier: AGPL-1.0
pragma solidity ^0.8.13;

contract SubSubTokens {
    constructor(address to, uint256 amount) {}

    string public constant symbol = "SubSubTokens";
}

struct MyStruct {
    uint256 test;
    bytes str;
}

contract SubSubTokens2 {
    constructor(SubSubTokens to, MyStruct memory data) {}

    string public constant symbol = "SubSubTokens2";
}


abstract contract AbstractContract {
    constructor(SubSubTokens to, MyStruct memory data) {}

}