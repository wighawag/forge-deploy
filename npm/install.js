#!/usr/bin/env node

const { install } = require("./binary");
install();

// const fs = require("fs");
// const path = require("path");
// const { execFileSync } = require("child_process");
// const { homedir } = require("os");

// const stdio = ["inherit", "inherit", "inherit"];

// const cargoDir = path.join(homedir(), ".cargo");
// if (!fs.existsSync(cargoDir)) {  
//   execFileSync("bash", ["-c", `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y`], { stdio });
// }

// if (!fs.existsSync("bin/forge-deploy")) {
//   const features = process.env.npm_config_features ? `--features ${process.env.npm_config_features.replace(",", " ")}` : "";
//   execFileSync("bash", ["-c", "-i", `PATH=$HOME/.cargo/bin:$PATH cargo install --root . forge-deploy --vers __VERSION__ ${features}`], { stdio });
// }
