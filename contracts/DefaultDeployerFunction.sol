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

    function _contextHasTag(string memory tag) internal returns (bool) {
        if (bytes(tag).length == 0) {
            return false;
        }
        return true;
    }

    function deploy(
        Deployer deployer,
        string memory name,
        string memory artifact,
        bytes memory args,
        DeployOptions memory options
    ) internal returns (address deployed) {
        if (_contextHasTag(options.proxyOnTag)) {
            Deployment memory existing = deployer.get(name);
            bytes memory bytecode = bytes.concat(vm.getCode(artifact), args);

            string memory implName = string.concat(name, "_Implementation");
            if (existing.addr != address(0)) {
                address implementation;
                Deployment memory existingImpl = deployer.get(implName);
                if (
                    existingImpl.addr == address(0) || 
                    keccak256(bytes.concat(existingImpl.bytecode, existingImpl.args)) != keccak256(bytes.concat(bytecode, args))
                ) {
                    // TODO implementation args
                    implementation = deploy(deployer, implName, artifact, args, DeployOptions({
                        deterministic: options.deterministic,
                        proxyOnTag: "",
                        proxyOwner: address(0)
                    }));
                } else {
                    implementation = existingImpl.addr;
                }
                deployed = existing.addr;
                vm.broadcast(options.proxyOwner);
                // TODO extra call data (upgradeToAndCall)
                EIP173Proxy(payable(deployed)).upgradeTo(implementation);
            } else {
                address implementation = deploy(deployer, implName, artifact, args, DeployOptions({
                    deterministic: options.deterministic,
                    proxyOnTag: "",
                    proxyOwner: address(0)
                }));
                
                // TODO extra call data
                bytes memory proxyArgs = abi.encode(implementation, options.proxyOwner, bytes(""));
                deployed = deploy(deployer, name, "ForgeDeploy_EIP173Proxy.sol:EIP173Proxy", proxyArgs, DeployOptions({
                    deterministic: options.deterministic,
                    proxyOnTag: "",
                    proxyOwner: address(0)
                }));
            }
        } else {
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
                
                
                deployer.save(name, deployed, bytecode, args, artifact);
            }
        }
        
    }
}