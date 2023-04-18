// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Deployer.g.sol";


 
string constant GreetingsRegistry_artifactPath = "GreetingsRegistry.sol";
string constant GreetingsRegistry_artifactContractName = "GreetingsRegistry";
 
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
// GENERATED
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------

import "src/GreetingsRegistry.sol";

// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
    

library DeployerFunctions{


// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
// GENERATED
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------

    
    function deploy_GreetingsRegistry(
        Deployer deployer,
        string memory name,
        
        string memory initialPrefix
        
    ) external returns (GreetingsRegistry) {
        return
            deploy_GreetingsRegistry(
                deployer,
                name,
                initialPrefix,
                DeployOptions({overrideIfExist: false})
            );
    }
    function deploy_GreetingsRegistry(
        Deployer deployer,
        string memory name,
        
        string memory initialPrefix,
        
        DeployOptions memory options
    ) public returns (GreetingsRegistry) {
        deployer._preCheck(name, options);
        GreetingsRegistry deployed = new GreetingsRegistry(initialPrefix);
        deployer.save(name, address(deployed), GreetingsRegistry_artifactPath, GreetingsRegistry_artifactContractName);
        return deployed;
    }
    
    
    // --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
  
}