// use std::{fs, collections::HashMap};

// use handlebars::Handlebars;
// use serde::{Deserialize, Serialize};
// use serde_json::{Value, from_str};
// use serde_json::Value::Object;
// use regex::Regex;
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
#[command(propagate_version = true)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Sync last broadcast with deployments
    Sync {name: Option<String> },
    // Generate Deployer Helper with Artifacts found
    Artifacts
}

fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Some(command) => {
            match command {
                Commands::Sync { name } => sync(name),
                Commands::Artifacts => artifacts()
            }
        }
        None => top()
    }
}

fn sync(name: &Option<String>) {
    println!("'forge-deploy sync' was used, name is: {name:?}")
}

fn artifacts() {
    println!("generating deployer...")
}

fn top() {
    println!("'myapp'")
}