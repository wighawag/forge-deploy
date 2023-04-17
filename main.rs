use std::{fs, path::Path};

// use handlebars::Handlebars;
use serde::{Deserialize, Serialize};
use serde_json;
use serde_json::Value;
// use serde_json::Value::Object;
// use regex::Regex;
use clap::{Parser, Subcommand};

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

// ------------

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct BytecodeJSON {
    object: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct ASTJSON {
    absolute_path: String,
    node_type: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct ArtifactJSON {
    abi: Vec<Value>,
    bytecode: BytecodeJSON,
    metadata: Option<Value>,
    ast: ASTJSON,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct ABIInput {
    internal_type: String,
    name: String,
    r#type: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct ABIConstructor {
    inputs: Vec<ABIInput>,
    state_mutability: String,
    r#type: String
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct ArtifactObject {
   data: ArtifactJSON,
   contract_name: String,
   solidity_filename: String,
   constructor: Value // TODO Option<ABIConstructor>
}

fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Some(command) => match command {
            Commands::Sync(args) => sync(&cli.root, &args.broadcasts),
            Commands::GenDeployer(args) => {
                artifacts(&cli.root, &args.artifacts, &args.sources, &args.output)
            }
        },
        None => top(),
    }
}

fn sync(root: &Option<String>, broadcasts: &Option<String>) {
    let root_folder = root.as_deref().unwrap_or(".");
    let broadcasts_folder = broadcasts.as_deref().unwrap_or("broadcast");

    println!("syncing broadcasts in {root_folder}/{broadcasts_folder} ...");
}

fn artifacts(
    root: &Option<String>,
    artifacts: &Option<String>,
    sources: &Option<String>,
    output: &Option<String>,
) {
    let root_folder = root.as_deref().unwrap_or(".");
    let artifacts_folder = artifacts.as_deref().unwrap_or("out");
    let sources_folder = sources.as_deref().unwrap_or("src");
    let generated_folder = output.as_deref().unwrap_or("generated");

    let folder_path_buf = Path::new(root_folder).join(artifacts_folder);
    let folder_path = folder_path_buf.to_str().unwrap();

    println!("generating deployer from {folder_path} ...");

    let mut artifacts: Vec<ArtifactObject> = Vec::new();

    for solidity_filepath_result in fs::read_dir(folder_path).unwrap() {
        match solidity_filepath_result {
            Ok(solidity_dir_entry) => {
                if !solidity_dir_entry.metadata().unwrap().is_file() {
                    // println!("solidity_filepath {}", solidity_filepath.path().display());
                    for contract_filepath_result in fs::read_dir(solidity_dir_entry.path()).unwrap()
                    {
                        let contract_dir_entry = contract_filepath_result.unwrap();
                        let contract_filepath = contract_dir_entry.path();
                        // println!("contract_filepath {}", contract_filepath.display());

                        let f = contract_filepath.to_str().unwrap();
                        if f.ends_with(".metadata.json") {
                            continue;
                        }

                        let data =
                            fs::read_to_string(f).expect("Unable to read file");
                        let res: ArtifactJSON =
                            serde_json::from_str(&data).expect("Unable to parse");
                        if res.ast.absolute_path.starts_with(sources_folder) {
                            // println!("res: {}", res.ast.absolute_path);
                            let constructor = res.abi[0].clone();
                            artifacts.push(ArtifactObject {
                                data: res,
                                contract_name: String::from(contract_dir_entry.file_name().to_str().unwrap().strip_suffix(".json").unwrap()),
                                solidity_filename: String::from(solidity_dir_entry.file_name().to_str().unwrap()),
                                constructor: constructor
                            });
                        }
                    }
                }
            }
            Err(_) => (),
        }
    }

    let generated_folder_path_buf = Path::new(root_folder).join(generated_folder);
    let generated_folder_path = generated_folder_path_buf.to_str().unwrap();
    generate_deployer(&artifacts, generated_folder_path);
}

fn top() {
    println!("'myapp'")
}

use handlebars::Handlebars;
fn generate_deployer(artifacts: &Vec<ArtifactObject>, generated_folder: &str) {
    for artifact in artifacts {
        println!("artifact: {}", artifact.data.ast.absolute_path);
    }

    let mut handlebars = Handlebars::new();
    handlebars.register_helper("memory-type", Box::new(memory_type));
    handlebars
        .register_template_string(
            "Deployer.g.sol",
            include_str!("templates/Deployer.g.sol.hbs"),
        )
        .unwrap();
    handlebars
        .register_template_string(
            "Artifacts.g.sol",
            include_str!("templates/Artifacts.g.sol.hbs"),
        )
        .unwrap();
    handlebars
        .register_template_string(
            "DeployScript.g.sol",
            include_str!("templates/DeployScript.g.sol.hbs"),
        )
        .unwrap();

    handlebars.set_strict_mode(true);

    let folder_path_buf = Path::new(generated_folder).join("deployer");
    let folder_path = folder_path_buf.to_str().unwrap();

    fs::create_dir_all(folder_path).expect("create folder");

    // fs::write(
    //     format!("{}/Deployer.g.sol", folder_path),
    //     format!(
    //         "{}",
    //         handlebars.render("Deployer.g.sol", artifacts).unwrap()
    //     ),
    // )
    // .expect("could not write file");
    // write_if_different(
    //     format!("{}/Artifacts.g.sol", folder_path),
    //     format!("{}",handlebars.render("Artifacts.g.sol", artifacts).unwrap()
    // );
    // fs::write(
    //     format!("{}/Artifacts.g.sol", folder_path),
    //     format!(
    //         "{}",
    //         handlebars.render("Artifacts.g.sol", artifacts).unwrap()
    //     ),
    // )
    // .expect("could not write file");

    // fs::write(
    //     format!("{}/DeployScript.g.sol", folder_path),
    //     format!(
    //         "{}",
    //         handlebars.render("DeployScript.g.sol", artifacts).unwrap()
    //     ),
    // )
    // .expect("could not write file");

    write_if_different(
        &format!("{}/Deployer.g.sol", folder_path), format!("{}",
        handlebars.render("Deployer.g.sol", artifacts).unwrap())
    );
    write_if_different(
        &format!("{}/Artifacts.g.sol", folder_path), format!("{}",
        handlebars.render("Artifacts.g.sol", artifacts).unwrap())
    );
    write_if_different(
        &format!("{}/DeployScript.g.sol", folder_path), format!("{}",
        handlebars.render("DeployScript.g.sol", artifacts).unwrap())
    );


    

}


fn write_if_different(path: &String, content: String) {
    // let bytes_to_write = content.as_bytes();

    let result = fs::read(path);
    let same = match result {
        Ok(existing) => String::from_utf8(existing).unwrap().eq(&content),
        Err(_e) => false
    };

    if !same {
        println!("writing new files...");
        fs::write(path, content).expect("could not write file");
    }
    
}

use handlebars::{RenderContext, Helper, Context, HelperResult, Output, JsonRender};

fn memory_type (h: &Helper, _: &Handlebars, _: &Context, _rc: &mut RenderContext, out: &mut dyn Output) -> HelperResult {
    let param = h.param(0).unwrap();

    let str_value = param.value().render();
    if str_value.eq("string") {
        out.write("memory")?;
    }
    
    Ok(())
}