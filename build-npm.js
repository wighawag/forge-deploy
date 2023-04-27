#!/usr/bin/env node
const args = process.argv.slice(2);

const {execFileSync} = require('child_process')
const fs = require("fs");
const stdio = ["inherit", "inherit", "inherit"];
execFileSync("cargo", ["install", "cargo-release"], {stdio});
execFileSync("cargo", ["install", "rust-to-npm"], {stdio});
execFileSync("npm", ["i", "-g", "rust-to-npm"], {stdio});
execFileSync("rust-to-npm", ["build"], {stdio});

// ------------------------------------------------------------------------------------------------
// FIX package.json // TODO use own template
// ------------------------------------------------------------------------------------------------
const pkg = JSON.parse(fs.readFileSync("package.json", 'utf-8'));
pkg.files.push("contracts");
delete pkg.main;
pkg.bin = {
    "forge-deploy": "start.js", // This seems needed as npm will install the bin script first and fails to fetch bin/forge-deploy then
    "forge-deploy-binary": "bin/forge-deploy"
}
delete pkg.scripts.uninstall;
pkg.scripts.preinstall = pkg.scripts.postinstall;
delete pkg.scripts.postinstall;
fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2));
// ------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------
// FIX pre-install.js to install locally
// ------------------------------------------------------------------------------------------------
const install_process = fs.readFileSync("pre-install.js", "utf-8");
fs.writeFileSync("pre-install.js", install_process.replace("cargo install forge-deploy", "cargo install --root . forge-deploy"))
// ------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------
// FIX start.js to use the local binary
// ------------------------------------------------------------------------------------------------
const start_process = fs.readFileSync("start.js", "utf-8");
fs.writeFileSync("start.js", start_process.replace(`"forge-deploy"`, `\`\${__dirname}/bin/forge-deploy \${process.argv.slice(2).join(' ')}\``));
// ------------------------------------------------------------------------------------------------

if (args[0] === 'publish') {
    execFileSync("cargo", ["release", "--execute"], {stdio});
    execFileSync("npm", ["publish"], {stdio});
} else {
    execFileSync("cargo", ["build"], {stdio});
}
