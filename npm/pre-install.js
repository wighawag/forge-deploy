const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const { homedir } = require("os");

const cargoDir = path.join(homedir(), ".cargo");

// check if directory exists
if (fs.existsSync(cargoDir)) {

} else {
  const stdio = ["inherit", "inherit", "inherit"];
  execFileSync("bash", ["-c", `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y`], { stdio });

  const features = process.env.npm_config_features ? `--features ${process.env.npm_config_features.replace(",", " ")}` : "";
  execFileSync("bash", ["-c", "-i", `PATH=$HOME/.cargo/bin:$PATH cargo install --root . forge-deploy --vers __VERSION__ ${features}`], { stdio });
}
