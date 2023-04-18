use serde_json;

use std::{fs, path::Path};

use crate::types::{ArtifactObject, ArtifactJSON};

pub fn get_artifacts(
    root_folder: &str,
    artifacts_folder: &str,
    sources_folder: &str
) -> Vec<ArtifactObject> {
    

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
                            // ensure the file exist as forge to not clean the out folder
                            if Path::new(res.ast.absolute_path.as_str()).exists() {
                                // println!("res: {}", res.ast.absolute_path);
                                let constructor = res.abi[0].clone();
                                artifacts.push(ArtifactObject {
                                    data: res,
                                    contract_name: String::from(contract_dir_entry.file_name().to_str().unwrap().strip_suffix(".json").unwrap()),
                                    solidity_filename: String::from(solidity_dir_entry.file_name().to_str().unwrap()),
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

    return artifacts;
}
