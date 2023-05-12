// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import "./Deployer.sol";

abstract contract DeployScript is Script {
    // TODO internal and make use of global deployer
    Deployer internal deployer = getDeployer();

    // global deplouyer
    // function setAutoBroadcast(bool broadcast) external {
    //     deployer.setAutoBroadcast(broadcast);
    // }

    // function activatePrank()

    function run() public virtual returns (DeployerDeployment[] memory newDeployments) {
        _deploy();

        // for each named deployer.save we got a new deployment
        // we return it so ti can get picked up by forge-deploy with the broadcasts
        return deployer.newDeployments();
    }

    function _deploy() internal {
        // TODO? pass msg.data as bytes
        // we would pass msg.data as bytes so the deploy function can make use of it if needed
        // bytes memory data = abi.encodeWithSignature("deploy(bytes)", msg.data);
        // IDEA: we could execute that version when msg.data.length > 0

        bytes memory data = abi.encodeWithSignature("deploy()");

        // we use a dynamic call to call deploy as we do not want to prescribe a return type
        (bool success, bytes memory returnData) = address(this).delegatecall(data);
        if (!success) {
            if (returnData.length > 0) {
                /// @solidity memory-safe-assembly
                assembly {
                    let returnDataSize := mload(returnData)
                    revert(add(32, returnData), returnDataSize)
                }
            } else {
                revert("FAILED_TO_CALL: deploy()");
            }
        }
    }
}
