// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DeployScript} from "generated/deployer/DeployScript.g.sol";
import {GreetingsRegistry} from "src/GreetingsRegistry.sol";
// import "generated/deployments/Deployments.g.sol";
import "generated/deployer/Deployer.g.sol";


contract DeployGreetingsRegistry is DeployScript {
   
    // you can also use the run function and this way pass params to your script
    // if so you need to ensure to return with the new deployments via:
    // `return _deployer.newDeployments();`
    // example:
    // function run() override public returns (DeployerDeployment[] memory newDeployments) {
    //  // .... _deployer.deploy...
    //  return _deployer.newDeployments();
    // }
    // this is how forge-deploy keep track of deployment names 
    // and how the forge-deploy sync command can generate the deployments files
    //
        
    function deploy() override internal {
        // we can get the existing registry thanks to generated code in generated/deployments/Deployments.g.sol
        
        // IMyTokens existing = Deployments.MyTokens;
        address existing = address(0);

        // // dynamic deploy of immutable contract
        // if (!_deployer.hasDeployed("MyRegistry")) {
        //     _deployer.save(
        //         "MyRegistry",
        //         address(new GreetingsRegistry(vm.toString(address(existing))))
        //     );
        // }


        // // dynamic deploy of upgradeable contract
        // if (!_deployer.hasDeployed("MyRegistry_Implementation")) {
        //     _deployer.save(
        //         "MyRegistry",
        //         address(new GreetingsRegistry(vm.toString(address(existing))))
        //     );
        // } else {

        // }
        

        // we can deploy a new contract and name it
        _deployer.deploy_GreetingsRegistry(
            "MyRegistry",
            vm.toString(address(existing)),
            DeployOptions({overrideIfExist: false})
        );

        _deployer.deploy_GreetingsRegistry(
            "MyRegistry",
            vm.toString(address(existing)),
            DeployOptions({overrideIfExist: true})
        );

        _deployer.deploy_GreetingsRegistry(
            "MyRegistry2",
            vm.toString(address(existing))
        );

        _deployer.deploy_GreetingsRegistry(
            "AnotherRegistry",
            vm.toString(address(existing))
        );
    }
}
