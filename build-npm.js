#!/usr/bin/env node
const args = process.argv.slice(2);

const {execFileSync} = require('child_process')
const fs = require("fs");
const stdio = ["inherit", "inherit", "inherit"];


const version_regex = /version[\s]*=[\s]*"(.*?)"/gm;
const cargo_toml = fs.readFileSync("Cargo.toml", "utf-8");
const version = [...version_regex.exec(cargo_toml)][1];
const pkg_version = (args[0] === 'publish:npm' || args[0] === 'npm:final') ? version : version + '-rc.1';

// ------------------------------------------------------------------------------------------------
// package.json
// ------------------------------------------------------------------------------------------------
const package_json = fs.readFileSync("npm/package.json", "utf-8");
fs.writeFileSync("package.json", package_json.replace("__VERSION__", pkg_version))
// ------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------
// install.js
// ------------------------------------------------------------------------------------------------
const install_js = fs.readFileSync("npm/install.js", "utf-8");
fs.writeFileSync("install.js", install_js.replace("__VERSION__", version))
// ------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------
// run.js
// ------------------------------------------------------------------------------------------------
const run_js = fs.readFileSync("npm/run.js", "utf-8");
fs.writeFileSync("run.js", run_js.replace("__VERSION__", version));
// ------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------
// binary.js
// ------------------------------------------------------------------------------------------------
const binary_js = fs.readFileSync("npm/binary.js", "utf-8");
fs.writeFileSync("binary.js", binary_js.replace("__VERSION__", version));
// ------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------
// binary.js: just copy
// ------------------------------------------------------------------------------------------------
const binary_install = fs.readFileSync("npm/binary-install.js", "utf-8");
fs.writeFileSync("binary-install.js", binary_install);
// ------------------------------------------------------------------------------------------------


if (args[0] === 'npm:final') {
    
} else if (args[0] === 'publish:npm') {
    execFileSync("npm", ["publish"], {stdio});
} else if (args[0] === 'publish') {
    execFileSync("forge", ["doc"], {stdio});
    execFileSync("cargo", ["install", "cargo-release"], {stdio});
    execFileSync("cargo", ["release", "--execute"], {stdio});
    execFileSync("npm", ["publish", "--tag", "rc"], {stdio});
} else {
    execFileSync("cargo", ["build"], {stdio});
}
