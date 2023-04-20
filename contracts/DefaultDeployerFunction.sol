// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Deployer.sol";
import "./proxy/ForgeDeploy_EIP173Proxy.sol";

struct DeployOptions {
    uint256 deterministic;
    string proxyOnTag;
    address proxyOwner;
}

library DefaultDeployerFunction{

    Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    /// @notice generic deploy function that save it using the deployer contract
    /// @param deployer contract that keep track of the deployments and save them
    /// @param name the deployment's name that will stored on disk in <deployments>/<context>/<name>.json
    /// @param artifact forge's artifact path <solidity file>.sol:<contract name>
    /// @param args encoded aergument for the contract's constructor
    function deploy(
        Deployer deployer,
        string memory name,
        string memory artifact,
        bytes memory args,
        DeployOptions memory options
    ) internal returns (address deployed) { // TODO return newDeployed ?
        if (deployer.isTagEnabled(options.proxyOnTag)) {
            // console.log("tag enabled");
            Deployment memory existing = deployer.get(name);
            bytes memory bytecode = bytes.concat(vm.getCode(artifact), args);

            string memory implName = string.concat(name, "_Implementation");
            if (existing.addr != address(0)) {
                // console.log("existing proxy:");
                // console.log(existing.addr);
                address implementation;
                Deployment memory existingImpl = deployer.get(implName);
                if (
                    existingImpl.addr == address(0) || 
                    keccak256(bytes.concat(existingImpl.bytecode, existingImpl.args)) != keccak256(bytes.concat(bytecode, args))
                ) {
                    // we will override the previous implementation
                    deployer.ignoreDeployment(implName);
                    // TODO implementation args
                    implementation = deploy(deployer, implName, artifact, args, DeployOptions({
                        deterministic: options.deterministic,
                        proxyOnTag: "",
                        proxyOwner: address(0)
                    }));
                    // console.log("new implementation for existing proxy:");
                    // console.log(implementation);
                    // console.log(artifact);
                } else {
                    // console.log("reusing impl:");
                    // console.log(existingImpl.addr);
                    implementation = existingImpl.addr;
                }
                deployed = existing.addr;
                vm.broadcast(options.proxyOwner);
                // TODO extra call data (upgradeToAndCall)
                EIP173Proxy(payable(deployed)).upgradeTo(implementation);
                // console.log("-- upgraded --");
            } else {
                // console.log("new proxy needed");
                deployer.ignoreDeployment(implName);
                address implementation = deploy(deployer, implName, artifact, args, DeployOptions({
                    deterministic: options.deterministic,
                    proxyOnTag: "",
                    proxyOwner: address(0)
                }));
                // console.log("new implementation:");
                // console.log(implementation);
                // console.log(artifact);
                
                // TODO extra call data
                bytes memory proxyArgs = abi.encode(implementation, options.proxyOwner, bytes(""));
                deployed = deploy(deployer, name, "ForgeDeploy_EIP173Proxy.sol:EIP173Proxy", proxyArgs, DeployOptions({
                    deterministic: options.deterministic,
                    proxyOnTag: "",
                    proxyOwner: address(0)
                }));
                // console.log("new proxy:");
                // console.log(deployed);
            }
        } else {
            // console.log("no tag");
            address existing = deployer.getAddress(name);
            if (existing == address(0)) {
                bytes memory bytecode = bytes.concat(vm.getCode(artifact), args);
                vm.broadcast();
                // TODO value
                if (options.deterministic > 0) {
                    uint256 salt = options.deterministic;
                    assembly {
                        deployed := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
                    }
                } else {
                    assembly {
                        deployed := create(0, add(bytecode, 0x20), mload(bytecode))
                    }
                }

                if (deployed == address(0)) {
                    revert(string.concat("Failed to deploy ", name));
                }
                
                // console.log("new deploy:");
                // console.log(deployed);
                
                deployer.save(name, deployed, bytecode, args, artifact);
            } else {
                deployed = existing;
                // console.log("existing deploy:");
                // console.log(deployed);
            }
        }
        
    }
}