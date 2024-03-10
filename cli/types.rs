use serde::{Deserialize, Serialize};
use serde_json;
use serde_json::Value;

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
pub struct ConstructorArgObject {
    pub name: String,
    pub memory_type: bool,
    pub r#type: String,
    pub custom_type: bool,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
pub struct ConstructorObject {
    pub args: Vec<ConstructorArgObject>,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
pub struct ContractObject {
    pub solidity_filepath: String,
    pub contract_name: String,
    pub solidity_filename: String,
    pub constructor: ConstructorObject,
}

// #[derive(Debug, Deserialize, Serialize, Clone, Default)]
// pub struct ImportObject {
//     pub solidity_filepath: String,
//     pub contract_names: Vec<String>,
//     pub constructor_types: Vec<String>,
// }

// #[derive(Debug, Deserialize, Serialize, Clone, Default)]
// pub struct ContractsInfo {
//     pub imports: Vec<ImportObject>,
//     pub contracts: Vec<ContractObject>,
// }

// ------------------------------------------------------------------------------------------------

pub struct DeploymentObject {
    pub name: String,
    pub address: String,
    pub bytecode: String,
    pub args_data: String,
    pub tx_hash: String,
    pub args: Option<Vec<String>>,
    pub data: String,
    pub contract_name: Option<String>,
    pub artifact_path: String,
    pub deployment_context: String,
    pub chain_id: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
pub struct BytecodeJSON {
    pub object: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "camelCase"))]
pub struct ASTJSON {
    pub absolute_path: String,
    pub node_type: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
pub struct ArtifactJSON {
    pub abi: Vec<Value>,
    pub bytecode: BytecodeJSON,
    pub metadata: Option<Value>
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "camelCase"))]
pub struct ABIInput {
    pub internal_type: String,
    pub name: String,
    pub r#type: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "camelCase"))]
pub struct ABIConstructor {
    pub inputs: Vec<ABIInput>,
    pub state_mutability: String,
    pub r#type: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
pub struct DeploymentJSON {
    pub address: String,
    pub abi: Vec<Value>,
    pub bytecode: String,
    pub args_data: String,
    pub tx_hash: String,
    pub args: Option<Vec<String>>,
    pub data: String,
}
