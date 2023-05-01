// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

/// @notice contract to read tags from a config file
/// Actually needed as Deployer constructor can't make external to itself
/// And we use external call to get around the issue of solidity not be able to try..catch abi decoding
contract TagsReader {
    // --------------------------------------------------------------------------------------------
    // Constants
    // --------------------------------------------------------------------------------------------
    Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    // --------------------------------------------------------------------------------------------
    // Public Interface
    // --------------------------------------------------------------------------------------------
    function readTagsFromContext(string calldata context) external returns (string[] memory tags) {
        string memory root = vm.projectRoot();

        // TODO configure file name ?
        string memory path = string.concat(root, "/contexts.json");
        string memory json = vm.readFile(path);
        return stdJson.readStringArray(json, string.concat(".", context, ".tags"));
    }
}

/// @notice contract that keep track of the deployment and save them as return value in the forge's broadcast
contract Deployer {
    // --------------------------------------------------------------------------------------------
    // Constants
    // --------------------------------------------------------------------------------------------
    Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    // --------------------------------------------------------------------------------------------
    // Storage
    // --------------------------------------------------------------------------------------------

    // Deployments
    mapping(string => DeployerDeployment) internal _namedDeployments;
    DeployerDeployment[] internal _newDeployments;

    // Context
    string internal deploymentContext;
    string internal chainIdAsString;
    mapping(string => bool) internal tags;

    // --------------------------------------------------------------------------------------------
    // Constrctor
    // --------------------------------------------------------------------------------------------

    /// @notice instantiate a deployer with the current context
    /// the context is by default the current chainId
    /// but if the DEPLOYMENT_CONTEXT env variable is set, the context take that value
    /// The context allow you to organise deployments in a set as well as make specific configurations
    constructor() {
        // TODO? allow to pass context in constructor
        uint256 currentChainID;
        assembly {
            currentChainID := chainid()
        }
        chainIdAsString = vm.toString(currentChainID);
        deploymentContext = _getDeploymentContext();
        _setTagsFromContext(deploymentContext);

        // we read the deployment folder for a .chainId file
        // if the chainId here do not match the current one
        // we are using the same context name on different chain, this is an error
        string memory root = vm.projectRoot();
        // TODO? configure deployments folder via deploy.toml / deploy.json
        string memory path = string.concat(root, "/deployments/", deploymentContext, "/.chainId");
        try vm.readFile(path) returns (string memory chainId) {
            if (keccak256(bytes(chainId)) != keccak256(bytes(chainIdAsString))) {
                revert(
                    string.concat(
                        "Current chainID: ",
                        chainIdAsString,
                        " But Context '",
                        deploymentContext,
                        "' Already Exists With a Different Chain ID (",
                        chainId,
                        ")"
                    )
                );
            }
        } catch {}
    }

    // --------------------------------------------------------------------------------------------
    // Public Interface
    // --------------------------------------------------------------------------------------------

    /// @notice function that return all new deployments as an array
    function newDeployments() external view returns (DeployerDeployment[] memory) {
        return _newDeployments;
    }

    // TODO save artifacts in a temporary folder and inject its path in the output
    // /// @notice function that record all deployment on a specific path and return that path
    // function recordNewDeploymentsAndReturnFilepath() external returns (string memory path) {
    //     // then the sync step can read it to get more info about the deployment, including the exact source, metadata....
    //     return "";
    // }

    /// @notice function that tell you whether a deployment already exists with that name
    /// @param name deployment's name to query
    /// @return exists whether the deployment exists or not
    function has(string memory name) public view returns (bool exists) {
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
    function getAddress(string memory name) public view returns (address payable addr) {
        DeployerDeployment memory existing = _namedDeployments[name];
        if (existing.addr != address(0)) {
            if (bytes(existing.name).length == 0) {
                return payable(address(0));
            }
            return existing.addr;
        }
        return _getExistingDeploymentAdress(name);
    }

    /// @notice allow to override an existing deployment by ignoring the current one.
    /// the deployment will only be overriden on disk once the broadast is performed and `forge-deploy` sync is invoked.
    /// @param name deployment's name to override
    function ignoreDeployment(string memory name) public {
        _namedDeployments[name].name = "";
        _namedDeployments[name].addr = payable(address(1)); // TO ensure it is picked up as being ignored
    }

    /// @notice function that return the deployment (address, bytecode and args bytes used)
    /// @param name deployment's name to query
    /// @return deployment the deployment (with address zero if not existent)
    function get(string memory name) public view returns (Deployment memory deployment) {
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

    /// @notice return true of the current context has the tag specified
    /// @param tag tag string to query
    ///  if the empty string is passed in, it will return false
    ///  if the string "*" is passed in, it will return true
    /// @return true if the tag is associated with the current context
    function isTagEnabled(string memory tag) external view returns (bool) {
        if (bytes(tag).length == 0) {
            return false;
        }
        bytes32 tagId = keccak256(bytes(tag));
        if (tagId == STAR) {
            return true;
        }
        return tags[tag];
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
            addr: payable(address(deployed)),
            bytecode: bytecode,
            args: args,
            artifact: artifact,
            deploymentContext: deploymentContext,
            chainIdAsString: chainIdAsString
        });
        _namedDeployments[name] = deployment;
        _newDeployments.push(deployment);
    }

    // --------------------------------------------------------------------------------------------
    // Internal
    // --------------------------------------------------------------------------------------------

    function _setTagsFromContext(string memory context) private {
        TagsReader tagReader = new TagsReader();

        // the context is its own tag
        tags[context] = true;

        try tagReader.readTagsFromContext(context) returns (string[] memory tagsRead) {
            for (uint256 i = 0; i < tagsRead.length; i++) {
                tags[tagsRead[i]] = true;
            }
        } catch {
            bytes32 contextID = keccak256(bytes(deploymentContext));
            if (contextID == CONTEXT_LOCALHOST) {
                tags["local"] = true;
                tags["testnet"] = true;
            } else if (contextID == CONTEXT_VOID) {
                tags["local"] = true;
                tags["testnet"] = true;
                tags["ephemeral"] = true;
            }
        }
    }

    function _getDeploymentContext() private returns (string memory context) {
        // no deploymentContext provided we fallback on chainID
        uint256 currentChainID;
        assembly {
            currentChainID := chainid()
        }
        context = vm.envOr("DEPLOYMENT_CONTEXT", string(""));
        if (bytes(context).length == 0) {
            // on local dev network we fallback on the special void context
            // this allow `forge test` without any env setup to work as normal, without trying to read deployments
            if (currentChainID == 1337 || currentChainID == 31337) {
                context = "void";
            } else {
                context = vm.toString(currentChainID);
            }
        }
    }

    // TODO if we could read folders, we could load all deployments in the constructor instead
    function _getExistingDeploymentAdress(string memory name) internal view returns (address payable) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", deploymentContext, "/", name, ".json");
        try vm.readFile(path) returns (string memory json) {
            bytes memory addr = stdJson.parseRaw(json, ".address");
            return abi.decode(addr, (address));
        } catch {
            return payable(address(0));
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
