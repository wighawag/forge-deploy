use std::{fs, path::Path};

use walkdir::WalkDir;
use regex::Regex;
use substring::Substring;


use crate::types::{ContractObject, ConstructorObject, InputObject};

struct ContractName {
    start: usize,
    end: usize,
    name: String,
}

pub fn get_contracts(
    root_folder: &str,
    sources_folder: &str
) -> Vec<ContractObject> {
    let match_comments = Regex::new(r#"(?m)(".*?"|'.*?')|(/\*.*?\*/|//[^\r\n]*$)"#).unwrap(); //gm
    let match_strings = Regex::new(r#"(".*?"|'.*?')"#).unwrap(); //g
    let match_contract_names = Regex::new(r#"(?m)contract[\s\r\n]*(\w*)[\s\r\n]"#).unwrap(); // gm
    let per_contract_match_constructor = Regex::new(r#"(?s)constructor[\s\r\n]*\((.*?)\)"#).unwrap(); // gs

    let folder_path_buf = Path::new(root_folder).join(sources_folder);
    let folder_path = folder_path_buf.to_str().unwrap();

    println!("generating deployer from {folder_path} ...");

    let mut contracts: Vec<ContractObject> = Vec::new();

    for entry in WalkDir::new(folder_path).into_iter().filter_map(|e| e.ok()) {
        if entry.metadata().unwrap().is_file() && entry.path().extension().unwrap().eq("sol") {
            let data =  fs::read_to_string(entry.path()).expect("Unable to read file");
            let data = match_comments.replace_all(&data, "");
            let data= match_strings.replace_all(&data, "");

            let mut contract_name_objects: Vec<ContractName> = Vec::new();

            let mut i = 0;
            for contract_names in match_contract_names.captures_iter(&data) {
                if let Some(the_match) = contract_names.get(0) {
                    if let Some(first_group) = contract_names.get(1) {
                        let contract_name = first_group.as_str();
                        let start = the_match.start();
                        if i > 0 {
                            contract_name_objects[i-1].end = start;
                        }
                        contract_name_objects.push(ContractName{
                            name: String::from(contract_name),
                            start: start,
                            end: data.len()
                        });
                        i = i + 1;
                    }
                }
                
            }

            for contract_name_object in contract_name_objects {

                let contract_string = data.substring(contract_name_object.start, contract_name_object.end);

                // println!("---------------------------------------");
                // println!("{}", contract_string);
                // println!("---------------------------------------");
                
                let constructor_string = match per_contract_match_constructor.captures(contract_string) {
                    Some(found) => match found.get(1) {
                        Some(constructor) => constructor.as_str(),
                        None => ""
                    },
                    None => ""
                };

                let args = constructor_string.split(",").map(|s| s.trim().split(" ").last().unwrap());
                
                let solidity_filepath = entry.path().to_str().unwrap();
                let solidity_filepath = solidity_filepath.substring(2, solidity_filepath.len());
                let contract = ContractObject {
                    solidity_filepath: String::from(solidity_filepath),
                    contract_name: String::from(contract_name_object.name),
                    solidity_filename: String::from(entry.file_name().to_str().unwrap()),
                    constructor: Some(ConstructorObject{
                        inputs: args.map(|arg| InputObject {name: String::from(arg), r#type: None}).collect()
                    }),
                    constructor_string: Some(String::from(constructor_string)),
                };
                println!("{:?}", contract);
                contracts.push(contract);
            }
        }
    }

    // for solidity_filepath_result in fs::read_dir(folder_path).unwrap() {
    //     match solidity_filepath_result {
    //         Ok(solidity_dir_entry) => {
    //             if !solidity_dir_entry.metadata().unwrap().is_file() {
    //                 // println!("solidity_filepath {}", solidity_filepath.path().display());
    //                 for contract_filepath_result in fs::read_dir(solidity_dir_entry.path()).unwrap()
    //                 {
    //                     let contract_dir_entry = contract_filepath_result.unwrap();
    //                     let contract_filepath = contract_dir_entry.path();
    //                     // println!("contract_filepath {}", contract_filepath.display());

    //                     let f = contract_filepath.to_str().unwrap();
    //                     if f.ends_with(".metadata.json") {
    //                         continue;
    //                     }

    //                     let data =
    //                         fs::read_to_string(f).expect("Unable to read file");
    //                     let res: ArtifactJSON =
    //                         serde_json::from_str(&data).expect("Unable to parse");
    //                     if res.ast.absolute_path.starts_with(sources_folder) {
    //                         // ensure the file exist as forge to not clean the out folder
    //                         if Path::new(res.ast.absolute_path.as_str()).exists() {
    //                             let solidity_filepath = res.ast.absolute_path;
    //                             // println!("res: {}", res.ast.absolute_path);
    //                             let constructor = res.abi[0].clone();
    //                             contracts.push(ContractObject {
    //                                 // data: res,
    //                                 contract_name: String::from(contract_dir_entry.file_name().to_str().unwrap().strip_suffix(".json").unwrap()),
    //                                 solidity_filename: String::from(solidity_dir_entry.file_name().to_str().unwrap()),
    //                                 solidity_filepath:String::from(solidity_filepath),
    //                                 constructor: constructor
    //                             });
    //                         } else {
    //                             // print!("do not exist: {}", res.ast.absolute_path);
    //                         }
    //                     }
    //                 }
    //             }
    //         }
    //         Err(_) => (),
    //     }
    // }

    return contracts;
}
