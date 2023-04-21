// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import "./Deployer.sol";

abstract contract DeployScript is Script {
    Deployer public deployer = new Deployer();

    function run() public virtual returns (DeployerDeployment[] memory newDeployments) {
        
        // we use a dynamic call to call deploy as we do not want to prescribe a return type
        // we pass msg.data as bytes so the deploy function can make use of it if needed
        bytes memory data = abi.encodeWithSignature("deploy(bytes)", msg.data);
        (bool success, bytes memory returndata) = address(this).delegatecall(data);
        if (!success) {
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        }

        // for each named deployer.save we got a new deployment
        // we return it so ti can get picked up by forge-deploy with the broadcasts
        return deployer.newDeployments();
    }
}
