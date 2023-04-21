use std::{fs, path::Path};

use serde::{Deserialize, Serialize};
use serde_json::{Value, Map};

use crate::types::DeploymentJSON;

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct MinimalDeploymentJSON {
    pub address: String,
    pub abi: Vec<Value>,
    // pub bytecode: Option<String>,
}

pub fn get_deployments(root_folder: &str, deployments_folder: &str, deployment_context: &str) -> Map<String, Value> {
    let mut deployments = Map::new();
    
    let folder_path_buf = Path::new(root_folder).join(deployments_folder).join(deployment_context);
    let folder_path = folder_path_buf.to_str().unwrap();

    println!("{}", folder_path);

    if let Ok(dir) = fs::read_dir(folder_path) {
        for json_filepath_result in dir {
            match json_filepath_result {
                Ok(json_file_entry) => {
                    let json_filename = json_file_entry.file_name();
                    let filename = json_filename.to_str().unwrap();
                    if filename.ends_with(".json") {
                        let deployment_name = filename.strip_suffix(".json").unwrap();
                        let data = fs::read_to_string(json_file_entry.path()).expect("Unable to read file");
                        let res: DeploymentJSON = serde_json::from_str(&data).expect("Unable to parse");
                        let mut object = Map::new();
                        object.insert("address".to_string(), Value::String(res.address));
                        object.insert("abi".to_string(), Value::Array(res.abi));
                        deployments.insert(deployment_name.to_string(), Value::Object(object));
                    }
                },
                Err(_) => (),
            }
        }    
    }
    
    return deployments;
}
    
pub fn export_minimal_deployments(deployments: &Map<String, Value>, out: Vec<&str>) {
    let data = serde_json::to_string_pretty(deployments).expect("Failed to stringify");
    let data_as_typescript = format!("export default {} as const;", data);
    // TODO js
    // let data_as_javascript = format!("export default {} as const;", data);
    for output in out {
        if (output.ends_with(".ts")) {
            fs::write(output, &data_as_typescript).expect("failed to write file");
        // TODO js
        // } else if (output.ends_with(".js")) {
        //     fs::write(output, &data_as_javascript).expect("failed to write file");
        } else {
            fs::write(output, &data).expect("failed to write file");
        }
        
    }
}
