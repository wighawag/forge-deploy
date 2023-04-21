// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/GreetingsRegistry.sol";
import "../script/Deploy.s.sol";

contract GreetingsRegistryTest is Test {
    GreetingsRegistry public registry;

    function setUp() public {
        registry = new Deployments().deploy("");
        registry.setMessage("hello", 1);
    }

    function testSetMessage() public {
        registry.setMessage("hello2", 1);
        assertEq(registry.messages(address(this)).content, string.concat(vm.toString(address(0)),"hello2"));
    }

}
