use clap::{Parser, Subcommand};

use std::{path::Path};

pub mod forge_artifacts;
pub mod src_artifacts;
pub mod deployer;
pub mod types;
pub mod forge_broadcasts;
pub mod sync;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
#[command(propagate_version = true)]
struct Cli {
    #[arg(short, long)]
    root: Option<String>,

    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Sync last broadcast with deployments
    Sync(SyncArgs),
    /// Generate Deployer Helper with Artifacts found
    GenDeployer(GenDeployerArgs),
}

#[derive(clap::Args)]
struct SyncArgs {
    #[arg(short, long)]
    broadcasts: Option<String>,
    deployments: Option<String>,
}

#[derive(clap::Args)]
struct GenDeployerArgs {
    #[arg(short, long)]
    artifacts: Option<String>,
    #[arg(short, long)]
    sources: Option<String>,
    #[arg(short, long)]
    output: Option<String>,
}

fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Some(command) => match command {
            Commands::Sync(args) => sync(&cli.root, &args.broadcasts, &args.deployments),
            Commands::GenDeployer(args) => {
                gen_deployer(true, &cli.root, &args.artifacts, &args.sources, &args.output)
            }
        },
        None => top(),
    }
}

fn gen_deployer(
    from_source: bool,
    root: &Option<String>,
    artifacts: &Option<String>,
    sources: &Option<String>,
    output: &Option<String>,
) {
    let root_folder = root.as_deref().unwrap_or(".");
    let artifacts_folder = artifacts.as_deref().unwrap_or("out");
    let sources_folder = sources.as_deref().unwrap_or("src");
    let generated_folder = output.as_deref().unwrap_or("generated");

    let contracts = if from_source { src_artifacts::get_contracts(root_folder, sources_folder) } else{ forge_artifacts::get_contracts(root_folder, artifacts_folder, sources_folder)};
    let generated_folder_path_buf = Path::new(root_folder).join(generated_folder);
    let generated_folder_path = generated_folder_path_buf.to_str().unwrap();
    deployer::generate_deployer(&contracts, generated_folder_path);
}

fn sync(root: &Option<String>, broadcasts: &Option<String>, deployments: &Option<String>) {
    let root_folder = root.as_deref().unwrap_or(".");
    let broadcasts_folder = broadcasts.as_deref().unwrap_or("broadcast");
    let deployments_folder = deployments.as_deref().unwrap_or("deployments");

    let broadcasts: Vec<types::BroadcastObject> = forge_broadcasts::get_last_broadcasts(root_folder, broadcasts_folder);
    sync::generate_deployments(&broadcasts, deployments_folder);
}

fn top() {
    println!("'forge-deploy'")
}
