use std::collections::HashMap;

use crate::types::{DeploymentObject};

pub fn generate_deployments(new_deployments: &HashMap<String, DeploymentObject>, deployments_folder: &str) {
    for (key, value) in new_deployments.iter() {
        println!("{} / {:?}", key, value);
    }
}