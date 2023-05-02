# Deployer
[Git Source](https://github.com/wighawag/forge-deploy/blob/044522a5f694bab9751162827b37a693cf0b557e/contracts/Deployer.sol)

contract that keep track of the deployment and save them as return value in the forge's broadcast


## State Variables
### vm

```solidity
Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));
```


### _namedDeployments

```solidity
mapping(string => DeployerDeployment) internal _namedDeployments;
```


### _newDeployments

```solidity
DeployerDeployment[] internal _newDeployments;
```


### deploymentContext

```solidity
string internal deploymentContext;
```


### chainIdAsString

```solidity
string internal chainIdAsString;
```


### tags

```solidity
mapping(string => bool) internal tags;
```


## Functions
### constructor

instantiate a deployer with the current context
the context is by default the current chainId
but if the DEPLOYMENT_CONTEXT env variable is set, the context take that value
The context allow you to organise deployments in a set as well as make specific configurations


```solidity
constructor();
```

### newDeployments

function that return all new deployments as an array


```solidity
function newDeployments() external view returns (DeployerDeployment[] memory);
```

### has

function that tell you whether a deployment already exists with that name


```solidity
function has(string memory name) public view returns (bool exists);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|deployment's name to query|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`exists`|`bool`|whether the deployment exists or not|


### getAddress

function that return the address of a deployment


```solidity
function getAddress(string memory name) public view returns (address payable addr);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|deployment's name to query|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`addr`|`address payable`|the deployment's address or the zero address|


### ignoreDeployment

allow to override an existing deployment by ignoring the current one.
the deployment will only be overriden on disk once the broadast is performed and `forge-deploy` sync is invoked.


```solidity
function ignoreDeployment(string memory name) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|deployment's name to override|


### get

function that return the deployment (address, bytecode and args bytes used)


```solidity
function get(string memory name) public view returns (Deployment memory deployment);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|deployment's name to query|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`deployment`|`Deployment`|the deployment (with address zero if not existent)|


### isTagEnabled

return true of the current context has the tag specified


```solidity
function isTagEnabled(string memory tag) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tag`|`string`|tag string to query if the empty string is passed in, it will return false if the string "*" is passed in, it will return true|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if the tag is associated with the current context|


### save

save the deployment info under the name provided
this is a low level call and is used by ./DefaultDeployerFunction.sol


```solidity
function save(string memory name, address deployed, string memory artifact, bytes memory args, bytes memory bytecode)
    public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|deployment's name|
|`deployed`|`address`|address of the deployed contract|
|`artifact`|`string`|forge's artifact path <solidity file>.sol:<contract name>|
|`args`|`bytes`|arguments' bytes provided to the constructor|
|`bytecode`|`bytes`|the contract's bytecode used to deploy the contract|


### save

save the deployment info under the name provided
this is a low level call and is used by ./DefaultDeployerFunction.sol


```solidity
function save(string memory name, address deployed, string memory artifact, bytes memory args) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|deployment's name|
|`deployed`|`address`|address of the deployed contract|
|`artifact`|`string`|forge's artifact path <solidity file>.sol:<contract name>|
|`args`|`bytes`|arguments' bytes provided to the constructor|


### save

save the deployment info under the name provided
this is a low level call and is used by ./DefaultDeployerFunction.sol


```solidity
function save(string memory name, address deployed, string memory artifact) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|deployment's name|
|`deployed`|`address`|address of the deployed contract|
|`artifact`|`string`|forge's artifact path <solidity file>.sol:<contract name>|


### _setTagsFromContext


```solidity
function _setTagsFromContext(string memory context) private;
```

### _getDeploymentContext


```solidity
function _getDeploymentContext() private returns (string memory context);
```

### _getExistingDeploymentAdress


```solidity
function _getExistingDeploymentAdress(string memory name) internal view returns (address payable);
```

### _getExistingDeployment


```solidity
function _getExistingDeployment(string memory name) internal view returns (Deployment memory deployment);
```

