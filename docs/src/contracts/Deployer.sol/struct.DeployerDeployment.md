# DeployerDeployment
[Git Source](https://github.com/wighawag/forge-deploy/blob/3c8c49a659495f80bba522311a7205aa2b215a95/contracts/Deployer.sol)

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

