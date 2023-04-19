// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Vm} from "forge-std/Vm.sol";
import "forge-std/console.sol";
import "forge-std/StdJson.sol";

/// @notice store the new deployment to be saved
struct DeployerDeployment {
    string name;
    address addr;
    bytes bytecode;
    bytes args;
    string artifact;
    string deploymentContext;
    string chainIdAsString;
}

/// @notice represent a deployment
struct Deployment {
    address addr;
    bytes bytecode;
    bytes args;
}

/// @notice contract that keep track of the deployment and save them as return value in the forge's broadcast
contract Deployer {

    // --------------------------------------------------------------------------------------------
    // Constants
    // --------------------------------------------------------------------------------------------
    Vm constant vm =
        Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    // --------------------------------------------------------------------------------------------
    // Storage
    // --------------------------------------------------------------------------------------------

    mapping(string => DeployerDeployment) internal _namedDeployments;
    DeployerDeployment[] internal _newDeployments;

    string internal deploymentContext;
    string internal chainIdAsString;

    // --------------------------------------------------------------------------------------------
    // Constrctor
    // --------------------------------------------------------------------------------------------

    /// @notice instantiate a deployer with the current context
    /// the context is by default the current chainId
    /// but if the DEPLOYMENT_CONTEXT env variable is set, the context take that value
    /// The context allow you to organise deployments in a set as well as make specific configurations
    constructor() {
        uint256 currentChainID;
        assembly {
            currentChainID := chainid()
        }
        chainIdAsString = vm.toString(currentChainID);
        deploymentContext = _getDeploymentContext();
        // we read the deployment folder for a .chainId file
        // if the chainId here do not match the current one
        // we are using the same context name on different chain, this is an error
        string memory root = vm.projectRoot();
        // TODO configure deployments folder
        string memory path = string.concat(root, "/deployments/", deploymentContext, "/.chainId");
        try vm.readFile(path) returns (string memory chainId) {
            if (keccak256(bytes(chainId)) != keccak256(bytes(chainIdAsString))) {
                revert(string.concat("Current chainID: ", chainIdAsString , " But Context '", deploymentContext, "' Already Exists With a Different Chain ID (", chainId ,")"));
            }
        } catch {
            // unfortunately we have to remove that as we cannot detect whether there is a directory for the deployment 
            // or if the directory is there but the .chainId file is not
            // uint256 currentChainID;
            // assembly {
            //     currentChainID := chainid()
            // }
            // string memory chainIdAsString = vm.toString(currentChainID);
            // if (keccak256(bytes(deploymentContext)) != keccak256(bytes(chainIdAsString))) {
            //     console.log(string.concat("the deployments folder for '", deploymentContext ,"' should have a .chainId file to prevent misusing it by mistake in another chain"));
            // }
        }
        
    }

    // --------------------------------------------------------------------------------------------
    // Public Interface
    // --------------------------------------------------------------------------------------------

    /// @notice function that return all new deployments as an array
    function newDeployments() external view returns (DeployerDeployment[] memory) {
        return _newDeployments;
    }

    /// @notice function that tell you whether a deployment already exists with that name
    /// @param name deployment's name to query
    /// @return exists whether the deployment exists or not
    function has(
        string memory name
    ) public view returns (bool exists) {
        DeployerDeployment memory existing = _namedDeployments[name];
        if (existing.addr != address(0)) {
            if (bytes(existing.name).length == 0) {
                return false;
            }
            return true;
        }
        return _getExistingDeploymentAdress(name) != address(0);
    }

    /// @notice function that return the address of a deployment
    /// @param name deployment's name to query
    /// @return addr the deployment's address or the zero address
    function getAddress(
        string memory name
    ) public view returns (address addr) {
        DeployerDeployment memory existing = _namedDeployments[name];
        if (existing.addr != address(0)) {
            if (bytes(existing.name).length == 0) {
                return address(0);
            }
            return existing.addr;
        }
        return _getExistingDeploymentAdress(name);
    }

    /// @notice allow to override an existing deployment by ignoring the current one.
    /// the deployment will only be overriden on disk once the broadast is performed and `forge-deploy` sync is invoked.
    /// @param name deployment's name to override
    function ignoreDeployment(
        string memory name
    ) public {
        _namedDeployments[name].name = "";
        _namedDeployments[name].addr = address(1); // TO ensure it is picked up as being ignored
    }

    /// @notice function that return the deployment (address, bytecode and args bytes used)
    /// @param name deployment's name to query
    /// @return deployment the deployment (with address zero if not existent)
    function get(
        string memory name
    ) public view returns (Deployment memory deployment) {
        DeployerDeployment memory newDeployment = _namedDeployments[name];
        if (newDeployment.addr != address(0)) {
            if (bytes(newDeployment.name).length > 0) {
                deployment.addr = newDeployment.addr;
                deployment.bytecode = newDeployment.bytecode;
                deployment.args = newDeployment.args;
            }
        } else {
            deployment = _getExistingDeployment(name);
        }
    }

    /// @notice save the deployment info under the name provided
    /// this is a low level call and is used by ./DefaultDeployerFunction.sol
    /// @param name deployment's name
    /// @param deployed address of the deployed contract
    /// @param bytecode the contract's bytecode used to deploy the contract
    /// @param args arguments' bytes provided to the constructor
    /// @param artifact forge's artifact path <solidity file>.sol:<contract name>
    function save(
        string memory name,
        address deployed,
        bytes memory bytecode,
        bytes memory args,
        string memory artifact
    ) public {
        require(bytes(name).length > 0, "EMPTY_NAME_NOT_ALLOWED");
        DeployerDeployment memory deployment = DeployerDeployment({
            name: name,
            addr: address(deployed),
            bytecode: bytecode,
            args: args,
            artifact: artifact,
            deploymentContext: deploymentContext,
            chainIdAsString: chainIdAsString
        });
        _namedDeployments[name] = deployment;
        _newDeployments.push(deployment);
        // TODO save artifacts in a temporary folder and inject its path in the output
        // then the sync step can read it to get more info about the deployment, including the exact source, metadata....
        // save(deployment);
    }

    // --------------------------------------------------------------------------------------------
    // Internal
    // --------------------------------------------------------------------------------------------

    function _getDeploymentContext() private returns (string memory context) {
        // no deploymentContext provided we fallback on chainID
        uint256 currentChainID;
        assembly {
            currentChainID := chainid()
        }
        context = vm.envOr("DEPLOYMENT_CONTEXT", vm.toString(currentChainID));
    }


    
    function _getExistingDeploymentAdress(string memory name) internal view returns (address) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", deploymentContext, "/", name, ".json");
        try vm.readFile(path) returns (string memory json) {
            bytes memory addr = stdJson.parseRaw(json, ".address");
            return abi.decode(addr, (address));
        } catch {
            return address(0);
        }
    }

    function _getExistingDeployment(string memory name) internal view returns (Deployment memory deployment) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", deploymentContext, "/", name, ".json");
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
