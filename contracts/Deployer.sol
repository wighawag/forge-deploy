// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Vm} from "forge-std/Vm.sol";
import "forge-std/console.sol";
import "forge-std/StdJson.sol";

/// @notice store the new deployment to be saved
struct DeployerDeployment {
    string name;
    address payable addr;
    bytes bytecode;
    bytes args;
    string artifact;
    string deploymentContext;
    string chainIdAsString;
}

/// @notice represent a deployment
struct Deployment {
    address payable addr;
    bytes bytecode;
    bytes args;
}

bytes32 constant CONTEXT_VOID = keccak256(bytes("void"));
bytes32 constant CONTEXT_LOCALHOST = keccak256(bytes("localhost"));
bytes32 constant STAR = keccak256(bytes("*"));


struct Deployer {
    DeployerDeployment[] newDeployments;
    mapping(string => DeployerDeployment) namedDeployments;
    string deploymentContext;
    string chainIdAsString;
    mapping(string => bool) tags;
}

library DeployerFunctions {

    Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    // --------------------------------------------------------------------------------------------
    // Public Interface
    // --------------------------------------------------------------------------------------------

    // TODO save artifacts in a temporary folder and inject its path in the output
    // /// @notice function that record all deployment on a specific path and return that path
    // function recordNewDeploymentsAndReturnFilepath() external returns (string memory path) {
    //     // then the sync step can read it to get more info about the deployment, including the exact source, metadata....
    //     return "";
    // }

    /// @notice function that tell you whether a deployment already exists with that name
    /// @param name deployment's name to query
    /// @return exists whether the deployment exists or not
    function has(Deployer storage deployer, string memory name) public view returns (bool exists) {
        DeployerDeployment memory existing = deployer.namedDeployments[name];
        if (existing.addr != address(0)) {
            if (bytes(existing.name).length == 0) {
                return false;
            }
            return true;
        }
        return getExistingDeploymentAdress(deployer, name) != address(0);
    }

    /// @notice function that return the address of a deployment
    /// @param name deployment's name to query
    /// @return addr the deployment's address or the zero address
    function getAddress(Deployer storage deployer, string memory name) public view returns (address payable addr) {
        DeployerDeployment memory existing = deployer.namedDeployments[name];
        if (existing.addr != address(0)) {
            if (bytes(existing.name).length == 0) {
                return payable(address(0));
            }
            return existing.addr;
        }
        return getExistingDeploymentAdress(deployer, name);
    }

    /// @notice allow to override an existing deployment by ignoring the current one.
    /// the deployment will only be overriden on disk once the broadast is performed and `forge-deploy` sync is invoked.
    /// @param name deployment's name to override
    function ignoreDeployment(Deployer storage deployer, string memory name) public {
        deployer.namedDeployments[name].name = "";
        deployer.namedDeployments[name].addr = payable(address(1)); // TO ensure it is picked up as being ignored
    }

    /// @notice function that return the deployment (address, bytecode and args bytes used)
    /// @param name deployment's name to query
    /// @return deployment the deployment (with address zero if not existent)
    function get(Deployer storage deployer, string memory name) public view returns (Deployment memory deployment) {
        DeployerDeployment memory newDeployment = deployer.namedDeployments[name];
        if (newDeployment.addr != address(0)) {
            if (bytes(newDeployment.name).length > 0) {
                deployment.addr = newDeployment.addr;
                deployment.bytecode = newDeployment.bytecode;
                deployment.args = newDeployment.args;
            }
        } else {
            deployment = getExistingDeployment(deployer, name);
        }
    }

    /// @notice return true of the current context has the tag specified
    /// @param tag tag string to query
    ///  if the empty string is passed in, it will return false
    ///  if the string "*" is passed in, it will return true
    /// @return true if the tag is associated with the current context
    function isTagEnabled(Deployer storage deployer, string memory tag) external view returns (bool) {
        if (bytes(tag).length == 0) {
            return false;
        }
        bytes32 tagId = keccak256(bytes(tag));
        if (tagId == STAR) {
            return true;
        }
        return deployer.tags[tag];
    }

    /// @notice save the deployment info under the name provided
    /// this is a low level call and is used by ./DefaultDeployerFunction.sol
    /// @param name deployment's name
    /// @param deployed address of the deployed contract
    /// @param artifact forge's artifact path <solidity file>.sol:<contract name>
    /// @param args arguments' bytes provided to the constructor
    /// @param bytecode the contract's bytecode used to deploy the contract
    function save(
        Deployer storage deployer, 
        string memory name,
        address deployed,
        string memory artifact,
        bytes memory args,
        bytes memory bytecode
    ) public {
        require(bytes(name).length > 0, "EMPTY_NAME_NOT_ALLOWED");
        DeployerDeployment memory deployment = DeployerDeployment({
            name: name,
            addr: payable(address(deployed)),
            bytecode: bytecode,
            args: args,
            artifact: artifact,
            deploymentContext: deployer.deploymentContext,
            chainIdAsString: deployer.chainIdAsString
        });
        deployer.namedDeployments[name] = deployment;
        deployer.newDeployments.push(deployment);
    }

    /// @notice save the deployment info under the name provided
    /// this is a low level call and is used by ./DefaultDeployerFunction.sol
    /// @param name deployment's name
    /// @param deployed address of the deployed contract
    /// @param artifact forge's artifact path <solidity file>.sol:<contract name>
    /// @param args arguments' bytes provided to the constructor
    function save(
        Deployer storage deployer, 
        string memory name,
        address deployed,
        string memory artifact,
        bytes memory args
    ) public {
        return save(deployer, name, deployed, artifact, args, vm.getCode(artifact));
    }

    /// @notice save the deployment info under the name provided
    /// this is a low level call and is used by ./DefaultDeployerFunction.sol
    /// @param name deployment's name
    /// @param deployed address of the deployed contract
    /// @param artifact forge's artifact path <solidity file>.sol:<contract name>
    function save(
        Deployer storage deployer, 
        string memory name,
        address deployed,
        string memory artifact
    ) public {
        return save(deployer, name, deployed, artifact, "", vm.getCode(artifact));
    }

    // --------------------------------------------------------------------------------------------
    // Internal
    // --------------------------------------------------------------------------------------------

    

    // TODO if we could read folders, we could load all deployments in the constructor instead
    function getExistingDeploymentAdress(Deployer storage deployer, string memory name) internal view returns (address payable) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", deployer.deploymentContext, "/", name, ".json");
        try vm.readFile(path) returns (string memory json) {
            bytes memory addr = stdJson.parseRaw(json, ".address");
            return abi.decode(addr, (address));
        } catch {
            return payable(address(0));
        }
    }

    function getExistingDeployment(Deployer storage deployer, string memory name) internal view returns (Deployment memory deployment) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", deployer.deploymentContext, "/", name, ".json");
        try vm.readFile(path) returns (string memory json) {
            bytes memory addrBytes = stdJson.parseRaw(json, ".address");
            bytes memory bytecodeBytes = stdJson.parseRaw(json, ".bytecode");
            bytes memory argsBytes = stdJson.parseRaw(json, ".args_data");
            deployment.addr = abi.decode(addrBytes, (address));
            deployment.bytecode = abi.decode(bytecodeBytes, (bytes));
            deployment.args = abi.decode(argsBytes, (bytes));
        } catch {}
    }
}
