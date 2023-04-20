// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-deploy/proxy/ForgeDeploy_Proxied.sol";

contract Empty is Proxied {
    constructor(string memory initialPrefix) {
        postUpgrade(initialPrefix);
    }
    function postUpgrade(string memory initialPrefix) public proxied {}
}
