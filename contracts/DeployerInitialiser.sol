// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Vm} from "forge-std/Vm.sol";
import {Deployer, DeployerDeployment} from "./Deployer.sol";
import {TagsReader} from "./TagsReader.sol";

bytes32 constant CONTEXT_VOID = keccak256(bytes("void"));
bytes32 constant CONTEXT_LOCALHOST = keccak256(bytes("localhost"));
bytes32 constant STAR = keccak256(bytes("*"));



library DeployerInitialiser {
    Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    function init(Deployer storage deployer) internal {
        // TODO? allow to pass context in constructor
        uint256 currentChainID;
        assembly {
            currentChainID := chainid()
        }
        deployer.chainIdAsString = vm.toString(currentChainID);
        deployer.deploymentContext = _getDeploymentContext();
        _setTagsFromContext(deployer, deployer.deploymentContext);

        // we read the deployment folder for a .chainId file
        // if the chainId here do not match the current one
        // we are using the same context name on different chain, this is an error
        string memory root = vm.projectRoot();
        // TODO? configure deployments folder via deploy.toml / deploy.json
        string memory path = string.concat(root, "/deployments/", deployer.deploymentContext, "/.chainId");
        try vm.readFile(path) returns (string memory chainId) {
            if (keccak256(bytes(chainId)) != keccak256(bytes(deployer.chainIdAsString))) {
                revert(
                    string.concat(
                        "Current chainID: ",
                        deployer.chainIdAsString,
                        " But Context '",
                        deployer.deploymentContext,
                        "' Already Exists With a Different Chain ID (",
                        chainId,
                        ")"
                    )
                );
            }
        } catch {}
    }

    // --------------------------------------------------------------------------------------------
    // PRIVATE (Used by constuctor)
    // --------------------------------------------------------------------------------------------
    function _setTagsFromContext(Deployer storage deployer, string memory context) private {
        TagsReader tagReader = new TagsReader();

        // the context is its own tag
        deployer.tags[context] = true;

        try tagReader.readTagsFromContext(context) returns (string[] memory tagsRead) {
            for (uint256 i = 0; i < tagsRead.length; i++) {
                deployer.tags[tagsRead[i]] = true;
            }
        } catch {
            bytes32 contextID = keccak256(bytes(deployer.deploymentContext));
            if (contextID == CONTEXT_LOCALHOST) {
                deployer.tags["local"] = true;
                deployer.tags["testnet"] = true;
            } else if (contextID == CONTEXT_VOID) {
                deployer.tags["local"] = true;
                deployer.tags["testnet"] = true;
                deployer.tags["ephemeral"] = true;
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
}