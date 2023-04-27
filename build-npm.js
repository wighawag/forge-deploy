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
// pre-install.js
// ------------------------------------------------------------------------------------------------
const pre_install_js = fs.readFileSync("npm/pre-install.js", "utf-8");
fs.writeFileSync("pre-install.js", pre_install_js.replace("__VERSION__", version))
// ------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------
// start.js
// ------------------------------------------------------------------------------------------------
const start_js = fs.readFileSync("npm/start.js", "utf-8");
fs.writeFileSync("start.js", start_js);
// ------------------------------------------------------------------------------------------------

if (args[0] === 'publish') {
    execFileSync("cargo", ["release", "--execute"], {stdio});
    execFileSync("npm", ["publish"], {stdio});
} else {
    execFileSync("cargo", ["build"], {stdio});
}
