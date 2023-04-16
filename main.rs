use std::{fs, collections::HashMap};

use handlebars::Handlebars;
use serde::{Deserialize, Serialize};
use serde_json::{Value, from_str};
use serde_json::Value::Object;
use regex::Regex;
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
    /// Adds files to myapp
    Add { name: Option<String> },
}

fn main() {
    let cli = Cli::parse();

    // You can check for the existence of subcommands, and if found use their
    // matches just as you would the top level cmd
    match &cli.command {
        Some(command) => {
            match(command) {
                Commands::Add { name } => {
                    println!("'myapp add' was used, name is: {name:?}")
                }
            }
        }
        None => println!("'myapp'")
    }
}