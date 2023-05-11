# DeployScript
[Git Source](https://github.com/wighawag/forge-deploy/blob/3c8c49a659495f80bba522311a7205aa2b215a95/contracts/DeployScript.sol)

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

