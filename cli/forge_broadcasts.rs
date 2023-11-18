use std::{collections::HashMap, fs, path::Path};

use crate::types::DeploymentObject;

use regex::Regex;
use serde::{Deserialize, Serialize};
use serde_json::Value::Object;
use serde_json::{from_str, Value};

#[derive(Serialize, Deserialize)]
#[derive(Debug)]
struct Contract {
    name: String,
    addr: String,
    bytecode: String,
    args: String,
    artifact: String,
    deploymentContext: String,
    chainIdAsString: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "camelCase"))]
pub struct Transaction {
    r#type: String, // example: "0x02"
    from: String,
    gas: String,           // example: "0xca531"
    value: Option<String>, // example:  "0x0"
    data: String,          // "0x..."
    nonce: String,         // example: "0xd5"
                           // "accessList": []
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "camelCase"))]
pub struct TransactionResult {
    hash: String,
    transaction_type: String, // CREATE, CREATE2
    contract_name: Option<String>,
    contract_address: Option<String>,
    arguments: Option<Vec<String>>,
    transaction: Transaction,
    function: Option<String>,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "camelCase"))]
pub struct FileContent {
    transactions: Vec<TransactionResult>,
    returns: Value,
}

pub fn get_last_deployments(
    root_folder: &str,
    broadcast_folder: &str,
) -> HashMap<String, DeploymentObject> {
    let re = Regex::new(r"\{(.+?)\}").unwrap();

    let folder_path_buf = Path::new(root_folder).join(broadcast_folder);

    let mut new_deployments: HashMap<String, DeploymentObject> = HashMap::new();

    for script_dir in fs::read_dir(folder_path_buf).unwrap() {
        match script_dir {
            Ok(script_dir) => {
                if script_dir.metadata().unwrap().is_dir() {
                    // println!("script {}", script_dir.path().display());
                    for chain_dir in fs::read_dir(script_dir.path()).unwrap() {
                        match chain_dir {
                            Ok(chain_dir) => {
                                if chain_dir.metadata().unwrap().is_dir() {
                                    // println!("chain: {}", chain_dir.path().display());
                                    let filepath_buf = chain_dir.path().join("run-latest.json");
                                    // let filepath = filepath_buf.to_str().unwrap();

                                    let data = fs::read_to_string(filepath_buf)
                                        .expect("Unable to read file");
                                    let res: FileContent =
                                        from_str(&data).expect("Unable to parse");
                                    let returns = res.returns;

                                    // collect transaction and associate them with contracts
                                    let mut transaction_per_deployments: HashMap<
                                        String,
                                        TransactionResult,
                                    > = HashMap::new();
                                    for transaction_result in res.transactions {
                                        if let Some(contract_address) =
                                            transaction_result.contract_address.clone()
                                        {
                                            transaction_per_deployments.insert(
                                                contract_address,
                                                transaction_result.clone(),
                                            );
                                        }
                                        // if transaction_result.transaction_type.eq("CREATE") {
                                        // }
                                        // TODO Create2
                                    }

                                    if let Object(returns) = returns {
                                        let deployments = returns.get("newDeployments");
                                        if let Some(deployments) = deployments {
                                            if deployments["internal_type"]
                                                == "struct DeployerDeployment[]"
                                            {
                                                let value: String =
                                                    deployments["value"].to_string();
                                                // println!("{}", value);
                                                let regex_result = re.captures_iter(value.as_str());

                                                for cap in regex_result {
                                                    let entry = cap[1].replace("\\\"", "").replace("\"\"", "");
                                                    let parts = entry.split(", ");
                                                    let collection = parts.collect::<Vec<&str>>();
                                                    let values: Vec<&str> = collection.iter()
                                                                                        .filter_map(|part| part.splitn(2, ": ").nth(1))
                                                                                        .collect();
                                                    let name = values[0];
                                                    let address = values[1];
                                                    let bytecode = values[2];
                                                    let args_data = values[3];
                                                    let artifact_full_path = values[4];
                                                    let deployment_context = values[5];
                                                    let chain_id = values[6];

                                                    // if deployment_context.eq("31337") || deployment_context.eq("1337") {
                                                    //     // for now we skip on dev network if no specific deployment context were specified
                                                    //     // this allow `forge test` to not read this by mistake ?
                                                    //     continue;
                                                    // }

                                                    if deployment_context.eq("void") {
                                                        // we do not keep track of the void context
                                                        continue;
                                                    }

                                                    let mut artifact_splitted =
                                                        artifact_full_path.split(":");
                                                    let artifact_path =
                                                        artifact_splitted.next().unwrap();
                                                    let contract_name = artifact_splitted.next();

                                                    if let Some(transaction_result) =
                                                        transaction_per_deployments.get(address)
                                                    {
                                                        let args =
                                                            transaction_result.arguments.clone();
                                                        let data = transaction_result
                                                            .transaction
                                                            .data
                                                            .to_string();
                                                        let tx_hash =
                                                            transaction_result.hash.to_string();

                                                        // "contractAddress": "0xBEe6FFc1E8627F51CcDF0b4399a1e1abc5165f15",
                                                        // "function": "upgradeTo(address)",
                                                        // if let Some(function) = &transaction_result.function {
                                                        //     if function.eq("upgradeTo(address)") {
                                                        //         println!("upgrade for {}", name.to_string())
                                                        //     }
                                                        // }

                                                        // println!("{}:{}", artifact_path, contract_name.unwrap_or("unknown"));
                                                        // println!("{} address: {}, artifact_path: {}, contract_name: {}, deployment_context: {}", name, address, artifact_path, contract_name, deployment_context);
                                                        new_deployments.insert(
                                                            format!(
                                                                "{}::{}",
                                                                deployment_context,
                                                                name.to_string()
                                                            ),
                                                            DeploymentObject {
                                                                name: name.to_string(),
                                                                address: address.to_string(),
                                                                bytecode: bytecode.to_string(),
                                                                args_data: args_data.to_string(),
                                                                tx_hash: tx_hash,
                                                                args: args,
                                                                data: data,
                                                                contract_name: contract_name
                                                                    .map(|s| s.to_string()),
                                                                artifact_path: artifact_path
                                                                    .to_string(),
                                                                deployment_context:
                                                                    deployment_context.to_string(),
                                                                chain_id: chain_id.to_string(),
                                                            },
                                                        );
                                                    } else {
                                                        new_deployments.insert(
                                                            format!(
                                                                "{}::{}",
                                                                deployment_context,
                                                                name.to_string()
                                                            ),
                                                            DeploymentObject {
                                                                name: name.to_string(),
                                                                address: address.to_string(),
                                                                bytecode: bytecode.to_string(),
                                                                args_data: args_data.to_string(),
                                                                tx_hash: "".to_string(),
                                                                args: Some(vec![]),
                                                                data: "".to_string(),
                                                                contract_name: contract_name
                                                                    .map(|s| s.to_string()),
                                                                artifact_path: artifact_path
                                                                    .to_string(),
                                                                deployment_context:
                                                                    deployment_context.to_string(),
                                                                chain_id: chain_id.to_string(),
                                                            },
                                                        );
                                                    }
                                                }
                                            } else {
                                                println!("not matching returns type")
                                            }
                                        } else {
                                            // println!("no deployments")
                                        }
                                    }
                                }
                            }
                            Err(_) => (),
                        }
                    }
                }
            }
            Err(_) => (),
        }
    }

    return new_deployments;
}
