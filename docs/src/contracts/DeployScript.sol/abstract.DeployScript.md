# DeployScript
[Git Source](https://github.com/wighawag/forge-deploy/blob/044522a5f694bab9751162827b37a693cf0b557e/contracts/DeployScript.sol)

**Inherits:**
Script


## State Variables
### deployer

```solidity
Deployer public deployer = new Deployer();
```


## Functions
### run


```solidity
function run() public virtual returns (DeployerDeployment[] memory newDeployments);
```

### _deploy


```solidity
function _deploy() internal;
```

