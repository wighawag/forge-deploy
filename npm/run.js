#!/usr/bin/env node

const { run } = require("./binary");
run();

// const { exec } = require("child_process");

// const controller = typeof AbortController !== "undefined" ? new AbortController() : { abort: () => {}, signal: typeof AbortSignal !== "undefined" ? new AbortSignal() : undefined };
// const { signal } = controller;

// exec(`${__dirname}/bin/forge-deploy ${process.argv.slice(2).join(' ')}`, { signal }, (error, stdout, stderr) => {
//   stdout && console.log(stdout);
//   stderr && console.error(stderr);
//   if (error !== null) {
//     console.log(`exec error: ${error}`);
//   }
// });

// process.on("SIGTERM", () => {
//   controller && controller.abort();
// });

// process.on("SIGINT", () => {
//   controller && controller.abort();
// });
    