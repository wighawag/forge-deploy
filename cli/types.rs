use serde::{Deserialize, Serialize};
use serde_json;
use serde_json::Value;

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct InputObject {
    pub name: String,
    pub r#type: Option<String> // TODO make it non-optional
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct ConstructorObject {
    pub inputs: Vec<InputObject>
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct ContractObject {
   pub solidity_filepath: String,
   pub contract_name: String,
   pub solidity_filename: String,
   pub constructor: Option<ConstructorObject>, // TODO make it non-optional
   pub constructor_string: Option<String>,
}

// ------------------------------------------------------------------------------------------------


#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
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


#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct DeploymentJSON {
    pub address: String,
    pub abi: Vec<Value>,
    pub bytecode: String,
    pub args_data: String,
    pub tx_hash: String,
    pub args: Option<Vec<String>>,
    pub data: String,
}

