# forge-deploy

A cli and associated contracts to keep track of deployments by name and reuse them in solidity.

It tries to keep compatibility with [hardhat-deploy](https://github.com/wighawag/hardhat-deploy) as far as possible (work in progress).

forge-deploy aims at provoding the minimal set of function to provide an elegant deployment system for foundry.

## Features
- generate type-safe deployment function for forge contracts. no need to pass in string of text and hope the abi encoded args are in the correct order or of the correct type.
- save deployments in json file (based on hardhat-deploy schema)
- modular system based on templates and solidity library


## Modularity 

The system is modular. The deploy functions provided by default offer a basic set of feature but the system can be extended by custom function easily. See [contracts/DefaultDeployerFunction.sol](./contracts/DefaultDeployerFunction.sol) and how this is a simple library that you can provide yourself. The only thing forge-deploy really provide is the specific set of functions in [contrats/Deployer.sol](./contracts/Deployer.sol) to `save` and `get` deployments



## How to use

1. have a forge project and cd into it

	```bash
	mkdir my-project;
	cd my-project;
	forge init;
	```

1. add the forge package

	```bash
	forge install wighawag/forge-deploy@v0.0.11;
	```

1. install the cli tool locally as the tool is likely to evolve rapidly

	```bash
	cargo install --version 0.0.11 --root . forge-deploy;
	```

	This will install version 0.0.11 in the bin folder,

	You can then execute it via 

	```bash
	./bin/forge-deploy <command> 
	```

	you can also compile it directly from the `lib/forge-deploy/` folder.

1. add to .gitignore the generated file + the binary we just installed

	```bash
	cat >> .gitignore <<EOF

	# forge-deploy
	/generated
	/deployments/localhost
	/deployments/31337

	# forge-deploy cli binary
	/.crates2.json
	/.crates.toml
	/bin
	EOF
	```

1. generate the type-safe deployment functions

	```bash
	./bin/forge-deploy gen-deployer;
	```

1. add a deploy script

	add the file  `script/Deploy.s.sol` with this content:

	```solidity
	// SPDX-License-Identifier: UNLICENSED
	pragma solidity ^0.8.13;

	import "forge-deploy/DeployScript.sol";
	import "generated/deployer/DeployerFunctions.g.sol";

	contract Deployments is DeployScript {
		using DeployerFunctions for Deployer;

		function deploy(bytes calldata) external returns (Counter) {
			return deployer.deploy_Counter("MyCounter");
		}
	}
	```

1. you also need to allow forge to read and write on certain paths by editing foundry.toml:

	```bash
	cat >> foundry.toml <<EOF

	fs_permissions = [
		{ access = "read", path = "./deployments"},
		{ access = "read", path = "./out"},
		{ access = "read", path = "./contexts.json"}
	]
	EOF
	```

	You might wonder what `context.json`. This is a configuration file. Its name might change in the future, but as of now, it let you configure context (like localhost, sepolia, mainnet) and specify a list of tag that you can then use in your deploy script to trigger diferent execution path.

1. You can now execute the script via forge script

	Note that you need to execute `./bin/forge-deploy sync` directly afterward

	For example:

	```bash
	forge script script/Counter.s.sol --rpc-url $RPC_URL --broadcast --private-key $DEPLOYER_PRIVATE_KEY -v && ./bin/forge-deploy sync;
	```

	with anvil and default account

	```bash
	DEPLOYMENT_CONTEXT=localhost forge script script/Counter.s.sol --rpc-url http://localhost:8545 --broadcast --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 -v && ./bin/forge-deploy sync;
	```

	Note that here we specify the DEPLOYMENT_CONTEXT env variable. This is necessary for localhost which use chain id 31337 as by default forge-deploy will not save the deployment on that chainId (same for 1337). This is so it does not interfere with in-memory tests which also use chainId=31337

	The DEPLOYMENT_CONTEXT env var also allows you to segregate different deployment context on the same network. If not specified, the context is the chainId

1. If you use [just](https://just.systems/), see example in [examples/basic](examples/basic) with its own [justfile](examples/basic/justfile)


## Quick Start

Get anvil started somewhere:
```bash
anvil;
```

then copy and execute this and see the result

```bash
mkdir my-forge-deploy-project;
cd my-forge-deploy-project;
forge init;
forge install wighawag/forge-deploy@v0.0.11;
cargo install --version 0.0.11 --root . forge-deploy;
cat >> foundry.toml <<EOF

fs_permissions = [
	{ access = "read", path = "./deployments"},
	{ access = "read", path = "./out"},
	{ access = "read", path = "./contexts.json"}
]
EOF
cat >> .gitignore <<EOF

# forge-deploy
/generated
/deployments/localhost
/deployments/31337

# forge-deploy cli binary
/.crates2.json
/.crates.toml
/bin
EOF
./bin/forge-deploy gen-deployer;
cat > script/Deploy.s.sol <<EOF
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-deploy/DeployScript.sol";
import "generated/deployer/DeployerFunctions.g.sol";

contract Deployments is DeployScript {
	using DeployerFunctions for Deployer;

	function deploy(bytes calldata) external returns (Counter) {
		return deployer.deploy_Counter("MyCounter");
	}
}
EOF
DEPLOYMENT_CONTEXT=localhost forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 -v && ./bin/forge-deploy sync;
```

### Reusable in tests

One great feature of forge's script that remains in forge-deploy is the ability to use script in tests.

This allow you to have your deployment procedure reusable in tests!

for example, here is a basic test for Counter. Copy the following content in the existing test/Counter.t.sol and run the test to see it in action:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../src/Counter.sol";
import "../script/Deploy.s.sol";
contract CounterTest is Test {
	Counter public counter;
	function setUp() public {
		counter = new Deployments().deploy("");
		counter.setNumber(0);
	}
	function testIncrement() public {
		counter.increment();
		assertEq(counter.number(), 1);
	}
		function testSetNumber(uint256 x) public {
			counter.setNumber(x);
			assertEq(counter.number(), x);
		}
}
```

As usual to run the tests you can do the following:

```
forge test
```

## More info

Note that the generated solidity is optional.

You can instead simply use the default deploy function

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-deploy/DeployScript.sol";
import "forge-deploy/DefaultDeployerFunction.sol";
import "../src/Counter.sol";

contract Deployments is DeployScript {
	using DefaultDeployerFunction for Deployer;

	function deploy(bytes calldata) external returns (Counter) {
		return Counter(
			deployer.deploy(
				"MyCounter",
				"Counter.sol:Counter", // forge's artifact id
				"", // no arguments: empty bytes
				DeployOptions({
							deterministic: 0, // 0 => no deterministic
							proxyOnTag: "", // empty string => no proxy
							proxyOwner: address(0)
					})
			)
		);
	}
}
```
