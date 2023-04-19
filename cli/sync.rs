use std::collections::HashMap;
use std::fs;
use std::{path::Path};

use crate::types::{DeploymentObject, ArtifactJSON, DeploymentJSON};

pub fn generate_deployments(root_folder: &str, deployment_folder: &str, artifacts_folder: &str, new_deployments: &HashMap<String, DeploymentObject>) {
    let out_folder_path_buf = Path::new(root_folder).join(deployment_folder);
    let artifact_folder_path_buf = Path::new(root_folder).join(artifacts_folder);

    for (_key, value) in new_deployments.iter() {
        let folder_path_buf = out_folder_path_buf.join(value.deployment_context.as_str());
        fs::create_dir_all(&folder_path_buf).expect("could not create folder");
        let chainid_file_path_buf = folder_path_buf.join(".chainId");
        if !chainid_file_path_buf.exists() {
            fs::write(chainid_file_path_buf, &value.chain_id).expect("failed to write the .chainId file");
        }

        // unfortunately forge do not export artifacts in the broadcast file, so we have to fetch in the out folder
        // if sync is called not directly, out folder could be out of sync and we would get wrong artifact data
        // TODO save artifact in the solidity execution in temporary files and fetch artifact data from there 

        // The following assume this is fixed: https://github.com/foundry-rs/foundry/issues/4760
        let artifact_solidity_folder_path_buf = artifact_folder_path_buf.join(&value.artifact_path);
        let contract_filename = match value.contract_name.clone() {
            Some(name) => format!("{}.json", name),
            None => {
                let mut res = fs::read_dir(&artifact_solidity_folder_path_buf).unwrap(); // .filter(|f| f.unwrap().file_name().to_str().unwrap().ends_with(()));
                res.next().unwrap().unwrap().file_name().to_str().unwrap().to_string()
            }
        };
        let artifact_path_buf = artifact_solidity_folder_path_buf.join(contract_filename);
        let data = fs::read_to_string(artifact_path_buf).expect("Unable to read file");
        let artifact: ArtifactJSON = serde_json::from_str(&data).expect("Unable to parse");


        let file_path_buf = folder_path_buf.join(format!("{}.json", value.name));

        let data = serde_json::to_string_pretty(&DeploymentJSON {
            address: value.address.to_string(),
            abi: artifact.abi,
            bytecode: value.bytecode.to_string(),
            args_data: value.args_data.to_string(),
            // TODO
            // args: value.args,
            // data: value.data
        }).expect("Failed to stringify");
        fs::write(file_path_buf, data).expect("failed to write file");
    }
}