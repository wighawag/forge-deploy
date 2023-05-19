use std::{fs, path::Path};

use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

use crate::types::DeploymentJSON;

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
pub struct MinimalDeploymentJSON {
    pub address: String,
    pub abi: Vec<Value>,
    // pub bytecode: Option<String>,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "camelCase"))]
pub struct ContextDeployments {
    pub name: String,
    pub chain_id: String,
    pub contracts: Map<String, Value>,
}

pub fn get_deployments(
    root_folder: &str,
    deployments_folder: &str,
    deployment_context: &str,
    include_args: bool,
) -> ContextDeployments {
    let mut deployments = Map::new();

    let folder_path_buf = Path::new(root_folder)
        .join(deployments_folder)
        .join(deployment_context);
    let folder_path = folder_path_buf.to_str().unwrap();

    println!("{}", folder_path);

    let mut chain_id: String = String::new();
    if let Ok(dir) = fs::read_dir(folder_path) {
        for json_filepath_result in dir {
            match json_filepath_result {
                Ok(json_file_entry) => {
                    let json_filename = json_file_entry.file_name();
                    let filename = json_filename.to_str().unwrap();
                    if filename.ends_with(".json") {
                        let deployment_name = filename.strip_suffix(".json").unwrap();
                        let data = fs::read_to_string(json_file_entry.path())
                            .expect("Unable to read file");
                        let res: DeploymentJSON =
                            serde_json::from_str(&data).expect("Unable to parse");
                        let mut object = Map::new();
                        object.insert("address".to_string(), Value::String(res.address));
                        object.insert("abi".to_string(), Value::Array(res.abi));
                        object.insert("tx_hash".to_string(), Value::String(res.tx_hash));
                        if include_args {
                            if let Some(args) = res.args {
                                let values = args
                                    .iter()
                                    .map(|v| serde_json::to_value(v).expect("failed to convert"))
                                    .collect();
                                object.insert("args".to_string(), Value::Array(values));
                            }
                        }

                        // object.insert("blockNumber".to_string(), Value::Array(res.abi));
                        // object.insert("blockTimestamp".to_string(), Value::Array(res.abi));
                        // object.insert("args".to_string(), Value::Array(res.abi));
                        deployments.insert(deployment_name.to_string(), Value::Object(object));
                    } else if filename.eq(".chainId") {
                        chain_id = fs::read_to_string(json_file_entry.path())
                            .expect("Unable to read file");
                    }
                }
                Err(_) => (),
            }
        }
    }

    let context_deployments = ContextDeployments {
        name: deployment_context.to_string(),
        chain_id: chain_id,
        contracts: deployments,
    };
    return context_deployments;
}

pub fn export_minimal_deployments(deployments: &ContextDeployments, out: Vec<&str>) {
    // let mut object = Map::new();
    // object.insert("name".to_string(), Value::String(depoyment_context.to_string()));
    // object.insert("chainId".to_string(), Value::String(deployment_chainid.to_string()));
    // object.insert("contracts".to_string(), Value::Object(deployments.clone()));

    let data = serde_json::to_string_pretty(deployments).expect("Failed to stringify");
    let data_as_typescript = format!("export default {} as const;", data);
    // TODO js
    // let data_as_javascript = format!("export default {} as const;", data);
    for output in out {
        if let Some(parent) = Path::new(output).parent() {
            fs::create_dir_all(parent).expect("create folder");
        }

        if output.ends_with(".ts") {
            fs::write(output, &data_as_typescript).expect("failed to write file");
        // TODO js
        // } else if (output.ends_with(".js")) {
        //     fs::write(output, &data_as_javascript).expect("failed to write file");
        } else {
            fs::write(output, &data).expect("failed to write file");
        }
    }
}
