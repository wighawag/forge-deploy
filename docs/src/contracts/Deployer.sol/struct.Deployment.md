# Deployment
[Git Source](https://github.com/wighawag/forge-deploy/blob/044522a5f694bab9751162827b37a693cf0b557e/contracts/Deployer.sol)

represent a deployment


```solidity
struct Deployment {
    address payable addr;
    bytes bytecode;
    bytes args;
}
```

