# DefaultDeployerFunction
[Git Source](https://github.com/wighawag/forge-deploy/blob/3c8c49a659495f80bba522311a7205aa2b215a95/contracts/DefaultDeployerFunction.sol)


## State Variables
### vm

```solidity
Vm private constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));
```


## Functions
### deploy

generic deploy function (to be used with Deployer)
`using DefaultDeployerFunction with Deployer;`


```solidity
function deploy(Deployer deployer, string memory name, string memory artifact, bytes memory args)
    internal
    returns (address payable deployed);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`deployer`|`Deployer`|contract that keep track of the deployments and save them|
|`name`|`string`|the deployment's name that will stored on disk in `<deployments>/<context>/<name>.json`|
|`artifact`|`string`|forge's artifact path `<solidity file>.sol:<contract name>`|
|`args`|`bytes`|encoded arguments for the contract's constructor|


### deploy

generic create2 deploy function (to be used with Deployer)
`using DefaultDeployerFunction with Deployer;`


```solidity
function deploy(
    Deployer deployer,
    string memory name,
    string memory artifact,
    bytes memory args,
    DeployOptions memory options
) internal returns (address payable deployed);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`deployer`|`Deployer`|contract that keep track of the deployments and save them|
|`name`|`string`|the deployment's name that will stored on disk in `<deployments>/<context>/<name>.json`|
|`artifact`|`string`|forge's artifact path `<solidity file>.sol:<contract name>`|
|`args`|`bytes`|encoded arguments for the contract's constructor|
|`options`|`DeployOptions`|options to specify for salt for deterministic deployment|


### _deploy


```solidity
function _deploy(
    Deployer deployer,
    string memory name,
    string memory artifact,
    bytes memory args,
    PrivateDeployOptions memory options
) private returns (address payable deployed);
```

