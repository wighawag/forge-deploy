// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {DeployerFunctions, Deployer, DeployerDeployment} from "./Deployer.sol";


abstract contract DeployScript is Script {
    using DeployerFunctions for Deployer;

    Deployer deployer;

    /// @notice instantiate a deploy script with the current context
    /// the context is by default the current chainId
    /// but if the DEPLOYMENT_CONTEXT env variable is set, the context take that value
    /// The context allow you to organise deployments in a set as well as make specific configurations
    constructor() {
        deployer.init();
    }

    function run() public virtual returns (DeployerDeployment[] memory newDeployments) {
        _deploy();

        // for each named deployer.save we got a new deployment
        // we return it so ti can get picked up by forge-deploy with the broadcasts
        return deployer.newDeployments;
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
