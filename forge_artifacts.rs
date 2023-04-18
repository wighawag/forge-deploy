use serde::{Deserialize, Serialize};
use serde_json;
use serde_json::Value;

use std::{fs, path::Path};

use crate::types::{ContractObject};


#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct BytecodeJSON {
    pub object: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct ASTJSON {
    pub absolute_path: String,
    pub node_type: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct ArtifactJSON {
    pub abi: Vec<Value>,
    pub bytecode: BytecodeJSON,
    pub metadata: Option<Value>,
    pub ast: ASTJSON,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct ABIInput {
    pub internal_type: String,
    pub name: String,
    pub r#type: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct ABIConstructor {
    pub inputs: Vec<ABIInput>,
    pub state_mutability: String,
    pub r#type: String
}



pub fn get_contracts(
    root_folder: &str,
    artifacts_folder: &str,
    sources_folder: &str
) -> Vec<ContractObject> {
    

    let folder_path_buf = Path::new(root_folder).join(artifacts_folder);
    let folder_path = folder_path_buf.to_str().unwrap();

    println!("generating deployer from {folder_path} ...");

    let mut contracts: Vec<ContractObject> = Vec::new();

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
                            // ensure the file exist as forge to not clean the out folder
                            if Path::new(res.ast.absolute_path.as_str()).exists() {
                                let solidity_filepath = res.ast.absolute_path;
                                // println!("res: {}", res.ast.absolute_path);
                                let constructor = res.abi[0].clone();
                                contracts.push(ContractObject {
                                    // data: res,
                                    contract_name: String::from(contract_dir_entry.file_name().to_str().unwrap().strip_suffix(".json").unwrap()),
                                    solidity_filename: String::from(solidity_dir_entry.file_name().to_str().unwrap()),
                                    solidity_filepath:String::from(solidity_filepath),
                                    constructor: constructor
                                });
                            } else {
                                // print!("do not exist: {}", res.ast.absolute_path);
                            }
                        }
                    }
                }
            }
            Err(_) => (),
        }
    }

    return contracts;
}
