# TagsReader
[Git Source](https://github.com/wighawag/forge-deploy/blob/044522a5f694bab9751162827b37a693cf0b557e/contracts/Deployer.sol)

contract to read tags from a config file
Actually needed as Deployer constructor can't make external to itself
And we use external call to get around the issue of solidity not be able to try..catch abi decoding


## State Variables
### vm

```solidity
Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));
```


## Functions
### readTagsFromContext


```solidity
function readTagsFromContext(string calldata context) external returns (string[] memory tags);
```

