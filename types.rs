use serde::{Deserialize, Serialize};
use serde_json;
use serde_json::Value;


#[derive(Debug, Deserialize, Serialize, Clone, Default)]
#[serde(rename_all(deserialize = "camelCase", serialize = "snake_case"))]
pub struct ArtifactObject {
   pub data: ArtifactJSON,
   pub contract_name: String,
   pub solidity_filename: String,
   pub constructor: Value // TODO Option<ABIConstructor>
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

