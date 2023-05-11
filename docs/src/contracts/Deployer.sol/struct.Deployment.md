# Deployment
[Git Source](https://github.com/wighawag/forge-deploy/blob/3c8c49a659495f80bba522311a7205aa2b215a95/contracts/Deployer.sol)

represent a deployment


```solidity
struct Deployment {
    address payable addr;
    bytes bytecode;
    bytes args;
}
```

