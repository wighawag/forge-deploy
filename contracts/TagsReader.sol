// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Vm} from "forge-std/Vm.sol";
import "forge-std/StdJson.sol";


/// @notice contract to read tags from a config file
/// Actually needed as Deployer constructor can't make external to itself
/// And we use external call to get around the issue of solidity not be able to try..catch abi decoding
contract TagsReader {
    // --------------------------------------------------------------------------------------------
    // Constants
    // --------------------------------------------------------------------------------------------
    Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    // --------------------------------------------------------------------------------------------
    // Public Interface
    // --------------------------------------------------------------------------------------------
    function readTagsFromContext(string calldata context) external returns (string[] memory tags) {
        string memory root = vm.projectRoot();

        // TODO configure file name ?
        string memory path = string.concat(root, "/contexts.json");
        string memory json = vm.readFile(path);
        return stdJson.readStringArray(json, string.concat(".", context, ".tags"));
    }
}
