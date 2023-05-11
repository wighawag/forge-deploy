# forge-deploy

A cli and associated contracts to keep track of deployments by name and reuse them in solidity.

It tries to keep compatibility with [hardhat-deploy](https://github.com/wighawag/hardhat-deploy) as far as possible (work in progress).

forge-deploy aims at providing the minimal set of function to provide an elegant deployment system for foundry.

## Template to get started:

https://github.com/wighawag/template-foundry

## Features

- generate type-safe deployment function for forge contracts. no need to pass in string of text and hope the abi encoded args are in the correct order or of the correct type.
- save deployments in json file (based on hardhat-deploy schema)
- modular system based on templates and solidity library

## Modularity

The system is modular. The deploy functions provided by default offer a basic set of feature but the system can be extended by custom function easily. See [contracts/DefaultDeployerFunction.sol](./contracts/DefaultDeployerFunction.sol) and how this is a simple library that you can provide yourself. The only thing forge-deploy really provide is the specific set of functions in [contrats/Deployer.sol](./contracts/Deployer.sol) to `save` and `get` deployments

## How to use

There are 2 way to get started, one [without npm](#without-npm) and one [with npm](#with-npm)

### with npm

1. have a forge project with npm and cd into it

   ```bash
   mkdir my-project;
   cd my-project;
   forge init;
   npm init
   ```

1. add the forge-deploy package

   ```bash
   npm i -D forge-deploy
   ```

   This will install the forge-deploy binary automatically

1. add to .gitignore the generated files

   ```bash
   cat >> .gitignore <<EOF

   # forge-deploy
   /generated
   /deployments/localhost
   /deployments/31337
   EOF
   ```

1. you also need to allow forge to read and write on certain paths by editing foundry.toml:

   ```bash
   cat >> foundry.toml <<EOF

   fs_permissions = [
   	{ access = "read", path = "./deployments"},
   	{ access = "read", path = "./out"},
   ]
   EOF
   ```

1. generate the type-safe deployment functions

   add some scripts in the package.json

   ```json
   {
     "scripts": {
       "compile": "forge-deploy gen-deployer && forge build",
       "deploy": "forge script script/Counter.s.sol --rpc-url $RPC_URL --broadcast --private-key $DEPLOYER_PRIVATE_KEY -v && forge-deploy sync;"
     }
   }
   ```

   Note how we execute `forge-deploy sync` directly after the script executiom. this is how forge-deploy will keep track of new deployments.

1. add a deploy script

   add the file `script/Deploy.s.sol` with this content:

   ```solidity
   // SPDX-License-Identifier: UNLICENSED
   pragma solidity ^0.8.13;

   import "forge-deploy/DeployScript.sol";
   import "generated/deployer/DeployerFunctions.g.sol";

   contract Deployments is DeployScript {
   	using DeployerFunctions for Deployer;

   	function deploy() external returns (Counter) {
   		return deployer.deploy_Counter("MyCounter");
   	}
   }
   ```

   The deploy function will be called and as the script extends DeployScript (which itself extends Script from forge-std) you ll have access to the deployer variable.

   This variable mostly expose save and get functions. Deploy functionality is actually implemented in library like the one provided here: "DeployerFunctions.g.sol", which is actually generated code from the command above: `forge-deploy gen-deployer;`

1. You can now execute the script via forge script

   ```bash
   npm run deploy
   ```

   Note that with anvil (localhost network), you need to set the DEPLOYMENT_CONTEXT env variable for forge-deploy to save the deployment

   ```bash
      DEPLOYMENT_CONTEXT=localhost npm run deploy
   ```

   This is necessary for localhost which use chain id 31337 as by default forge-deploy will not save the deployment on that chainId (same for 1337). This is so it does not interfere with in-memory tests which also use chainId=31337

   The DEPLOYMENT_CONTEXT env var also allows you to segregate different deployment context on the same network. If not specified, the context is the chainId

### without npm

1. have a forge project and cd into it

   ```bash
   mkdir my-project;
   cd my-project;
   forge init;
   ```

1. add the forge-deploy package

   ```bash
   forge install wighawag/forge-deploy@v0.0.34;
   ```

1. build the cli directly from lib/forge-deploy

   ```bash
   cd lib/forge-deploy;
   cargo build --release;
   cp target/release/forge-deploy ../../forge-deploy;
   ```

   In the last step above, we also copy it in the project folder for easy access;

   This way you can then execute it via the following:

   ```bash
   ./forge-deploy <command>
   ```

   You could also download the binaries (if you dont want to use cargo): https://github.com/wighawag/forge-deploy/releases

1. add to .gitignore the generated file + the binary we just installed

   ```bash
   cat >> .gitignore <<EOF

   # forge-deploy
   /generated
   /deployments/localhost
   /deployments/31337

   # forge-deploy cli binary
   /forge-deploy
   EOF
   ```

1. you also need to allow forge to read and write on certain paths by editing foundry.toml:

   ```bash
   cat >> foundry.toml <<EOF

   fs_permissions = [
   	{ access = "read", path = "./deployments"},
   	{ access = "read", path = "./out"}
   ]
   EOF
   ```

1. generate the type-safe deployment functions

   ```bash
   ./forge-deploy gen-deployer;
   ```

1. add a deploy script

   add the file `script/Deploy.s.sol` with this content:

   ```solidity
   // SPDX-License-Identifier: UNLICENSED
   pragma solidity ^0.8.13;

   import "forge-deploy/DeployScript.sol";
   import "generated/deployer/DeployerFunctions.g.sol";

   contract Deployments is DeployScript {
   	using DeployerFunctions for Deployer;

   	function deploy() external returns (Counter) {
   		return deployer.deploy_Counter("MyCounter");
   	}
   }
   ```

   The deploy function will be called and as the script extends DeployScript (which itself extends Script from forge-std) you ll have access to the deployer variable.

   This variable mostly expose save and get functions. Deploy functionality is actually implemented in library like the one provided here: "DeployerFunctions.g.sol", which is actually generated code from the command above: `./forge-deploy gen-deployer;`

1. You can now execute the script via forge script

   Note that you need to execute `./forge-deploy sync` directly afterward

   For example:

   ```bash
   forge script script/Counter.s.sol --rpc-url $RPC_URL --broadcast --private-key $DEPLOYER_PRIVATE_KEY -v && ./forge-deploy sync;
   ```

   with anvil and default account

   ```bash
   DEPLOYMENT_CONTEXT=localhost forge script script/Counter.s.sol --rpc-url http://localhost:8545 --broadcast --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 -v && ./forge-deploy sync;
   ```

   Note that here we specify the DEPLOYMENT_CONTEXT env variable. This is necessary for localhost which use chain id 31337 as by default forge-deploy will not save the deployment on that chainId (same for 1337). This is so it does not interfere with in-memory tests which also use chainId=31337

   The DEPLOYMENT_CONTEXT env var also allows you to segregate different deployment context on the same network. If not specified, the context is the chainId

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
forge install wighawag/forge-deploy@v0.0.34;
cd lib/forge-deploy;
cargo build --release;
cp target/release/forge-deploy ../../forge-deploy;
cd ../..;
cat >> foundry.toml <<EOF

fs_permissions = [
	{ access = "read", path = "./deployments"},
	{ access = "read", path = "./out"}
]
EOF
cat >> .gitignore <<EOF

# forge-deploy
/generated
/deployments/localhost
/deployments/31337

EOF
./forge-deploy gen-deployer;
cat > script/Deploy.s.sol <<EOF
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-deploy/DeployScript.sol";
import "generated/deployer/DeployerFunctions.g.sol";

contract Deployments is DeployScript {
	using DeployerFunctions for Deployer;

	function deploy() external returns (Counter) {
		return deployer.deploy_Counter("MyCounter");
	}
}
EOF
DEPLOYMENT_CONTEXT=localhost forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 -v && ./forge-deploy sync;
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
		counter = new Deployments().deploy();
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

	function deploy() external returns (Counter) {
		return Counter(
			deployer.deploy(
				"MyCounter",
				"Counter.sol:Counter", // forge's artifact id
				"" // no arguments: empty bytes
			)
		);
	}
}
```
