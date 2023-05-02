# DeployerDeployment
[Git Source](https://github.com/wighawag/forge-deploy/blob/044522a5f694bab9751162827b37a693cf0b557e/contracts/Deployer.sol)

store the new deployment to be saved


```solidity
struct DeployerDeployment {
    string name;
    address payable addr;
    bytes bytecode;
    bytes args;
    string artifact;
    string deploymentContext;
    string chainIdAsString;
}
```

