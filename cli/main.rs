use clap::{Parser, Subcommand};

use std::path::{Path, PathBuf};

pub mod deployer;
pub mod forge_broadcasts;
pub mod forge_deploy_deployments;
pub mod src_artifacts;
pub mod sync;
pub mod types;

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
    /// Export deployments for a particular context
    Export(ExportArgs),
}

#[derive(clap::Args)]
struct SyncArgs {
    #[arg(short, long)]
    broadcasts: Option<String>,
    #[arg(short, long)]
    deployments: Option<String>,
    #[arg(short, long)]
    artifacts: Option<String>,
}

#[derive(clap::Args)]
struct GenDeployerArgs {
    #[arg(short, long)]
    templates: Option<String>,
    #[arg(short, long)]
    artifacts: Option<String>,
    #[arg(short, long)]
    sources: Option<String>,
    #[arg(short, long)]
    output: Option<String>,
}

#[derive(clap::Args)]
struct ExportArgs {
    deployment_context: String,
    output: String,
    #[arg(short, long)]
    deployments: Option<String>,
}

fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Some(command) => match command {
            Commands::Sync(args) => sync(
                &cli.root,
                &args.broadcasts,
                &args.deployments,
                &args.artifacts,
            ),
            Commands::GenDeployer(args) => {
                gen_deployer(&cli.root, &args.templates, &args.sources, &args.output)
            }
            Commands::Export(args) => export(
                &cli.root,
                &args.deployment_context,
                &args.output,
                &args.deployments,
            ),
        },
        None => top(),
    }
}

fn gen_deployer(
    root: &Option<String>,
    templates: &Option<String>,
    sources: &Option<String>,
    output: &Option<String>,
) {
    let root_folder = root.as_deref().unwrap_or(".");
    let sources_folder = sources.as_deref().unwrap_or("src");
    let generated_folder = output.as_deref().unwrap_or("generated");

    let contracts = src_artifacts::get_contracts(root_folder, sources_folder);
    let generated_folder_path_buf = Path::new(root_folder).join(generated_folder);
    let generated_folder_path = generated_folder_path_buf.to_str().unwrap();

    let template_paths = if let Some(templates) = templates {
        templates
            .split(",")
            .map(|v| PathBuf::from(v))
            .collect::<Vec<PathBuf>>()
    } else {
        Vec::new()
    };
    deployer::generate_deployer(&contracts, &template_paths, generated_folder_path);
}

fn sync(
    root: &Option<String>,
    broadcasts: &Option<String>,
    deployments: &Option<String>,
    artifacts: &Option<String>,
) {
    let root_folder = root.as_deref().unwrap_or(".");
    let broadcasts_folder = broadcasts.as_deref().unwrap_or("broadcast");
    let deployments_folder = deployments.as_deref().unwrap_or("deployments");
    let artifacts_folder = artifacts.as_deref().unwrap_or("out");

    let new_deployments = forge_broadcasts::get_last_deployments(root_folder, broadcasts_folder);
    sync::generate_deployments(
        root_folder,
        deployments_folder,
        artifacts_folder,
        &new_deployments,
    );
}

fn export(
    root: &Option<String>,
    deployment_context: &str,
    out: &str,
    deployments: &Option<String>,
) {
    let root_folder = root.as_deref().unwrap_or(".");
    let deployments_folder = deployments.as_deref().unwrap_or("deployments");

    let deployments = forge_deploy_deployments::get_deployments(
        root_folder,
        deployments_folder,
        deployment_context,
    );

    forge_deploy_deployments::export_minimal_deployments(&deployments, out.split(",").collect());
}

fn top() {
    println!("'forge-deploy'")
}
