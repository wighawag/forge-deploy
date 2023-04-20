# forge-deploy

A cli and associated contracts to keep track of deployments by name and reuse them in solidity.

It tries to keep compatibility with [hardhat-deploy](https://github.com/wighawag/hardhat-deploy) as far as possible (work in progress).

## Features
- generate type-safe deployment function for forge contracts. no need to pass in string of text and hope the abi encoded args are in the correct order.
- save deployments in json file (based on hardhat-deploy schema)

## How to use

0. have a forge project and cd into it

```
cd my-project
forge init # if needed
```

1. add the forge package

```
forge install wighawag/forge-deploy
```


2. install the cli tool locally as the tool is likely to evolve rapidly
```
cargo install --version 0.0.2 --root . forge-deploy
```

This will install version 0.0.2 in the bin folder,

You can then execute it via 

```
./bin/forge-deploy <command> ...
```

you can also compile it directly from the `lib/forge-deploy/` folder.


3.
add a deploy script, see below example

Note that to provide type-safety `forge-deploy` provide a `gen-deployer` command to generate type-safe deploy function for all contracts

```
./bin/forge-deploy gen-deployer
```

4. add to .gitignore the generated file + the binary we just installed

```
echo -e "\n\n#forge-deploy\n/generated" >> .gitignore;
echo -e "\n#forge-deploy binary\n/.crates2.json\n/.crates.toml\n/bin" >> .gitignore;
```

5. copy this file in `script/Counter.s.sol`

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-deploy/DeployScript.sol";
import "generated/deployer/DeployerFunctions.g.sol";

contract CounterScript is DeployScript {
    using DeployerFunctions for Deployer;

    function deploy() override internal {
        _deployer.deploy_Counter("MyCounter");
    }
}
```

6. You can now execute the script via forge script

Note that you need to execute `./bin/forge-deploy sync` directly afterward

For example:

```
forge script script/Counter.s.sol --rpc-url $RPC_URL --broadcast --private-key $DEPLOYER_PRIVATE_KEY -v && ./bin/forge-deploy sync
```

with anvil and default account

```
forge script script/Counter.s.sol --rpc-url http://localhost:8545 --broadcast --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 -v && ./bin/forge-deploy sync  
```

6. If you use [just](https://just.systems/), see example in [examples/basic](examples/basic) with its own [justfile](examples/basic/justfile)


## Quick Start

Get anvil started somewhere:
```
anvil
```

then copy this and see the result

```
mkdir my-forge-deploy-project;
cd my-forge-deploy-project;
forge init;
forge install wighawag/forge-deploy;
cargo install --version 0.0.2 --root . forge-deploy;
echo -e "\n\n#forge-deploy\n/generated" >> .gitignore;
echo -e "\n#forge-deploy binary\n/.crates2.json\n/.crates.toml\n/bin" >> .gitignore;
./bin/forge-deploy gen-deployer;
cat > script/Counter.s.sol <<EOF
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-deploy/DeployScript.sol";
import "generated/deployer/DeployerFunctions.g.sol";

contract CounterScript is DeployScript {
    using DeployerFunctions for Deployer;

    function deploy() override internal {
        _deployer.deploy_Counter("MyCounter");
    }
}
EOF
forge script script/Counter.s.sol --rpc-url http://localhost:8545 --broadcast --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 -v && ./bin/forge-deploy sync;
```