# TagsReader
[Git Source](https://github.com/wighawag/forge-deploy/blob/3c8c49a659495f80bba522311a7205aa2b215a95/contracts/Deployer.sol)

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

