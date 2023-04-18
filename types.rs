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
