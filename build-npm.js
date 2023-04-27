#!/usr/bin/env node
const args = process.argv.slice(2);

const {execFileSync} = require('child_process')
const fs = require("fs");
const stdio = ["inherit", "inherit", "inherit"];
execFileSync("cargo", ["install", "cargo-release"], {stdio});
execFileSync("cargo", ["install", "rust-to-npm"], {stdio});
execFileSync("npm", ["i", "-g", "rust-to-npm"], {stdio});
execFileSync("rust-to-npm", ["build"], {stdio});
const pkg = JSON.parse(fs.readFileSync("package.json", 'utf-8'));
pkg.files.push("contracts");
fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2));

if (args[0] === 'publish') {
    execFileSync("cargo", ["release", "--execute"], {stdio});
    execFileSync("npm", ["publish"], {stdio});
}
