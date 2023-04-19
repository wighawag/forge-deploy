// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import "./Deployer.sol";

abstract contract DeployScript is Script {
    Deployer internal _deployer = new Deployer();

    function run() public virtual returns (DeployerDeployment[] memory newDeployments) {
        deploy();
        return _deployer.newDeployments();
    }

    /// @notice function to be overriden to execute a deployment script
    /// this take care of returning the deployment saved by the deployer contract
    function deploy() virtual internal {

    }
}
