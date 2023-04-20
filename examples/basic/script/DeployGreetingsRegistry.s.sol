// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-deploy/DeployScript.sol";
import "generated/deployer/DeployerFunctions.g.sol";

contract DeployGreetingsRegistry is DeployScript {
    using DeployerFunctions for Deployer;
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

        if (_deployer.has("MyRegistry")){
            console.log("MyRegistry already deployed");
            console.log(_deployer.getAddress("MyRegistry"));
        } else {
            console.log("No MyRegistry deployed yet");
        }
        
        _deployer.deploy_Counter("MyCounter");

        // we can deploy a new contract and name it
        _deployer.deploy_GreetingsRegistry(
            "MyRegistry",
            vm.toString(address(existing)),
            DeployOptions({deterministic: 0, proxyOnTag: "", proxyOwner: address(0)})
        );

        if (_deployer.has("MyRegistry")){
            console.log("MyRegistry is now deployed");
            console.log(_deployer.getAddress("MyRegistry"));
        } else {
            console.log("Still No MyRegistry deployed yet");
        }

        _deployer.ignoreDeployment("MyRegistry");
        _deployer.deploy_GreetingsRegistry(
            "MyRegistry",
            vm.toString(address(existing)),
            DeployOptions({deterministic: 0, proxyOnTag: "", proxyOwner: address(0)})
        );

        console.log(_deployer.getAddress("MyRegistry"));
        
        _deployer.deploy_GreetingsRegistry(
            "MyRegistry2",
            vm.toString(address(existing))
        );

        _deployer.deploy_GreetingsRegistry(
            "AnotherRegistry",
            vm.toString(address(existing))
        );


        // this fails in anvil
        
        // _deployer.deploy_GreetingsRegistry(
        //     "DeterministicRegistry",
        //     vm.toString(address(existing)),
        //     DeployOptions({deterministic: 23, proxyOnTag: "", proxyOwner: address(0)})
        // );

        // _deployer.deploy_GreetingsRegistry(
        //     "DeterministicRegistry2",
        //     vm.toString(address(existing)),
        //     DeployOptions({deterministic: 2, proxyOnTag: "", proxyOwner: address(0)})
        // );


        // proxy tests

        _deployer.deploy_GreetingsRegistry(
            "ProxiedRegistry",
            vm.toString(address(existing)),
            DeployOptions({deterministic: 0, proxyOnTag: "local", proxyOwner: vm.envAddress("DEPLOYER")})
        );

        _deployer.deploy_GreetingsRegistry(
            "ProxiedRegistry",
            vm.toString(address(existing)),
            DeployOptions({deterministic: 0, proxyOnTag: "local", proxyOwner: vm.envAddress("DEPLOYER")})
        );

        _deployer.deploy_Empty(
            "ProxiedRegistry",
            vm.toString(address(existing)),
            DeployOptions({deterministic: 0, proxyOnTag: "local", proxyOwner: vm.envAddress("DEPLOYER")})
        );
    }
}
