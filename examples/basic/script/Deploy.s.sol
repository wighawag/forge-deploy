// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-deploy/DeployScript.sol";
import "generated/deployer/DeployerFunctions.g.sol";

contract Deployments is DeployScript {
    using DeployerFunctions for Deployer;
    // you can also use the run function and this way pass params to your script
    // if so you need to ensure to return with the new deployments via:
    // `return deployer.newDeployments();`
    // example:
    // function run() override public returns (DeployerDeployment[] memory newDeployments) {
    //  // .... deployer.deploy...
    //  return deployer.newDeployments();
    // }
    // this is how forge-deploy keep track of deployment names
    // and how the forge-deploy sync command can generate the deployments files
    //

    function deploy() external returns (GreetingsRegistry registry) {
        // we can get the existing registry thanks to generated code in generated/deployments/Deployments.g.sol

        // IMyTokens existing = Deployments.MyTokens;
        address existing = address(0);

        // // dynamic deploy of immutable contract
        // if (!deployer.hasDeployed("MyRegistry")) {
        //     deployer.save(
        //         "MyRegistry",
        //         address(new GreetingsRegistry(vm.toString(address(existing))))
        //     );
        // }

        // // dynamic deploy of upgradeable contract
        // if (!deployer.hasDeployed("MyRegistry_Implementation")) {
        //     deployer.save(
        //         "MyRegistry",
        //         address(new GreetingsRegistry(vm.toString(address(existing))))
        //     );
        // } else {

        // }

        if (deployer.has("MyRegistry")) {
            console.log("MyRegistry already deployed");
            console.log(deployer.getAddress("MyRegistry"));
        } else {
            console.log("No MyRegistry deployed yet");
        }

        deployer.deploy_Counter("MyCounter");

        // we can deploy a new contract and name it
        registry = deployer.deploy_GreetingsRegistry(
            "MyRegistry",
            vm.toString(address(existing)),
            DeployOptions({deterministic: 0, proxyOnTag: "", proxyOwner: address(0)})
        );

        if (deployer.has("MyRegistry")) {
            console.log("MyRegistry is now deployed");
            console.log(deployer.getAddress("MyRegistry"));
        } else {
            console.log("Still No MyRegistry deployed yet");
        }

        deployer.ignoreDeployment("MyRegistry");
        deployer.deploy_GreetingsRegistry(
            "MyRegistry",
            vm.toString(address(existing)),
            DeployOptions({deterministic: 0, proxyOnTag: "", proxyOwner: address(0)})
        );

        console.log(deployer.getAddress("MyRegistry"));

        deployer.deploy_GreetingsRegistry("MyRegistry2", vm.toString(address(existing)));

        deployer.deploy_GreetingsRegistry("AnotherRegistry", vm.toString(address(existing)));

        // this fails in anvil

        // deployer.deploy_GreetingsRegistry(
        //     "DeterministicRegistry",
        //     vm.toString(address(existing)),
        //     DeployOptions({deterministic: 23, proxyOnTag: "", proxyOwner: address(0)})
        // );

        // deployer.deploy_GreetingsRegistry(
        //     "DeterministicRegistry2",
        //     vm.toString(address(existing)),
        //     DeployOptions({deterministic: 2, proxyOnTag: "", proxyOwner: address(0)})
        // );

        // proxy tests

        deployer.deploy_GreetingsRegistry(
            "ProxiedRegistry",
            vm.toString(address(existing)),
            DeployOptions({deterministic: 0, proxyOnTag: "local", proxyOwner: vm.envAddress("DEPLOYER")})
        );

        deployer.deploy_GreetingsRegistry(
            "ProxiedRegistry",
            vm.toString(address(existing)),
            DeployOptions({deterministic: 0, proxyOnTag: "local", proxyOwner: vm.envAddress("DEPLOYER")})
        );

        deployer.deploy_Empty(
            "ProxiedRegistry",
            vm.toString(address(existing)),
            DeployOptions({deterministic: 0, proxyOnTag: "local", proxyOwner: vm.envAddress("DEPLOYER")})
        );
    }
}
