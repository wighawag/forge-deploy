# forge-deploy

A cli and associated contracts to keep track of deployments by name and reuse them in solidity.

It tries to keep compatibility with [hardhat-deploy](https://github.com/wighawag/hardhat-deploy) as far as possible (work in progress).

## Features
- generate type-safe deployment function for forge contracts. no need to pass in string of text and hope the abi encoded args are in the correct order.
- save deployments in json file (based on hardhat-deploy schema)

## How to use

1. have a forge project and cd into it

    ```
    mkdir my-project;
    cd my-project;
    forge init;
    ```

1. add the forge package

    ```
    forge install wighawag/forge-deploy@v0.0.10;
    ```

1. install the cli tool locally as the tool is likely to evolve rapidly

    ```
    cargo install --version 0.0.10 --root . forge-deploy;
    ```

    This will install version 0.0.10 in the bin folder,

    You can then execute it via 

    ```
    ./bin/forge-deploy <command> 
    ```

    you can also compile it directly from the `lib/forge-deploy/` folder.

1. add to .gitignore the generated file + the binary we just installed

    ```
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

    ```
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

    ```
    echo '\nfs_permissions = [{ access = "read", path = "./deployments"}, { access = "read", path = "./out"}, { access = "read", path = "./contexts.json"}]' >> foundry.toml;
    ```

    You might wonder what `context.json`. This is a configuration file. Its name might change in the future, but as of now, it let you configure context (like localhost, sepolia, mainnet) and specify a list of tag that you can then use in your deploy script to trigger diferent execution path.

1. You can now execute the script via forge script

    Note that you need to execute `./bin/forge-deploy sync` directly afterward

    For example:

    ```
    forge script script/Counter.s.sol --rpc-url $RPC_URL --broadcast --private-key $DEPLOYER_PRIVATE_KEY -v && ./bin/forge-deploy sync;
    ```

    with anvil and default account

    ```
    forge script script/Counter.s.sol --rpc-url http://localhost:8545 --broadcast --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 -v && ./bin/forge-deploy sync;
    ```

1. If you use [just](https://just.systems/), see example in [examples/basic](examples/basic) with its own [justfile](examples/basic/justfile)


## Quick Start

Get anvil started somewhere:
```
anvil;
```

then copy and execute this and see the result

```
mkdir my-forge-deploy-project;
cd my-forge-deploy-project;
forge init;
forge install wighawag/forge-deploy@v0.0.10;
cargo install --version 0.0.10 --root . forge-deploy;
echo '\nfs_permissions = [{ access = "read", path = "./deployments"}, { access = "read", path = "./out"}, { access = "read", path = "./contexts.json"}]' >> foundry.toml;
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
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 -v && ./bin/forge-deploy sync;
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

As usual to run the tests you can use `forge test`

Here we set the DEPLOYMENT_CONTEXT to "void" to prevent the test from reading in the generated deployments folder "31337"

This is related to a feature we did not talk much yet, that of deployment context that allow you to segregate contracts on the same network in different bucket.

More doc will come

```
DEPLOYMENT_CONTEXT=void forge test
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
				"MyCounter2",
				"Counter.sol:Counter",
				DeployOptions({
            				deterministic: 0,
            				proxyOnTag: "",
            				proxyOwner: address(0)
        			})
			)
		);
	}
}
```
