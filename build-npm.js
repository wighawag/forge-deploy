#!/usr/bin/env node
const args = process.argv.slice(2);

const {execFileSync} = require('child_process')
const fs = require("fs");
const stdio = ["inherit", "inherit", "inherit"];
execFileSync("cargo", ["install", "cargo-release"], {stdio});

const version_regex = /version[\s]*=[\s]*"(.*?)"/gm;
const cargo_toml = fs.readFileSync("Cargo.toml", "utf-8");
const version = [...version_regex.exec(cargo_toml)][1];

// ------------------------------------------------------------------------------------------------
// package.json
// ------------------------------------------------------------------------------------------------
const package_json = fs.readFileSync("npm/package.json", "utf-8");
fs.writeFileSync("package.json", package_json.replace("__VERSION__", version))
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


if (args[0] === 'publish') {
    execFileSync("cargo", ["release", "--execute"], {stdio});
    execFileSync("npm", ["publish", "--tag", "next"], {stdio});
} else {
    execFileSync("cargo", ["build"], {stdio});
}
