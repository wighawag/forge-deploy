use std::{fs, path::Path};

use path_slash::PathExt;
use regex::Regex;
use substring::Substring;
use walkdir::WalkDir;

use crate::types::{ConstructorArgObject, ConstructorObject, ContractObject};

struct ContractName {
    start: usize,
    end: usize,
    name: String,
}

// TODO better
static INTERNAL_TYPES: [&str; 103] = [
    "uint",
    "uint256",
    "uint8",
    "uint16",
    "uint24",
    "uint32",
    "uint40",
    "uint48",
    "uint56",
    "uint64",
    "uint72",
    "uint80",
    "uint88",
    "uint96",
    "uint104",
    "uint112",
    "uint120",
    "uint128",
    "uint136",
    "uint144",
    "uint152",
    "uint160",
    "uint168",
    "uint176",
    "uint184",
    "uint192",
    "uint200",
    "uint208",
    "uint216",
    "uint232",
    "uint240",
    "uint248",
    "uint256",
    "int",
    "int256",
    "int8",
    "int16",
    "int24",
    "int32",
    "int40",
    "int48",
    "int56",
    "int64",
    "int72",
    "int80",
    "int88",
    "int96",
    "int104",
    "int112",
    "int120",
    "int128",
    "int136",
    "int144",
    "int152",
    "int160",
    "int168",
    "int176",
    "int184",
    "int192",
    "int200",
    "int208",
    "int216",
    "int232",
    "int240",
    "int248",
    "int256",
    "bytes1",
    "bytes2",
    "bytes3",
    "bytes4",
    "bytes5",
    "bytes6",
    "bytes7",
    "bytes8",
    "bytes9",
    "bytes10",
    "bytes11",
    "bytes12",
    "bytes13",
    "bytes14",
    "bytes15",
    "bytes16",
    "bytes17",
    "bytes18",
    "bytes19",
    "bytes20",
    "bytes21",
    "bytes22",
    "bytes23",
    "bytes24",
    "bytes25",
    "bytes26",
    "bytes27",
    "bytes28",
    "bytes29",
    "bytes30",
    "bytes31",
    "bytes32",
    "string",
    "bytes",
    "address",
    "bool",
    "address payable",
];
fn is_custom_type(t: &str) -> bool {
    if INTERNAL_TYPES.contains(&t) {
        return false;
    }
    for i in INTERNAL_TYPES.map(|v| format!("{}[", v)) {
        if t.starts_with(i.as_str()) {
            return false;
        }
    }
    // TODO not full proof, name ufixed_myname will be considered non-custom
    if t.starts_with("ufixed") {
        return false;
    }
    if t.starts_with("fixed") {
        return false;
    }
    return true;
}

pub fn get_contracts(root_folder: &str, sources_folder: &str) -> Vec<ContractObject> {
    let match_comments = Regex::new(r#"(?ms)(".*?"|'.*?')|(/\*.*?\*/|//[^\r\n]*$)"#).unwrap(); //gm
    let match_strings = Regex::new(r#"(?m)(".*?"|'.*?')"#).unwrap(); //g
    let match_contract_names = Regex::new(r#"(?m)(abstract)?[\s]+contract[\s]+(\w*)[\s]"#).unwrap(); // gm
    let per_contract_match_constructor = Regex::new(r#"(?s)constructor[\s]*\((.*?)\)"#).unwrap(); // gs

    let folder_path_buf = Path::new(root_folder).join(sources_folder);
    let folder_path = folder_path_buf.to_str().unwrap();

    // println!("generating deployer from {folder_path} ...");

    let mut contracts: Vec<ContractObject> = Vec::new();
    // let mut imports: Vec<ImportObject> = Vec::new();

    for entry in WalkDir::new(folder_path).into_iter().filter_map(|e| e.ok()) {
        if entry.metadata().unwrap().is_file() && entry.path().extension().unwrap().eq("sol") {
            let data = fs::read_to_string(entry.path()).expect("Unable to read file");
            let data = match_comments.replace_all(&data, "");
            let data = match_strings.replace_all(&data, "");

            // let import_map: HashMap<String, bool> = HashMap::new();
            let mut contract_name_objects: Vec<ContractName> = Vec::new();

            let mut i = 0;
            for contract_names in match_contract_names.captures_iter(&data) {
                if let Some(the_match) = contract_names.get(0) {
                    if let Some(first_group) = contract_names.get(2) {
                        let is_abstract = match contract_names.get(1) {
                            Some(str) => str.as_str().eq("abstract"),
                            None => false,
                        };

                        if !is_abstract {
                            let contract_name = first_group.as_str();
                            let start = the_match.start();
                            if i > 0 {
                                contract_name_objects[i - 1].end = start;
                            }
                            contract_name_objects.push(ContractName {
                                name: String::from(contract_name),
                                start: start,
                                end: data.len(),
                            });
                            i = i + 1;
                        }
                    }
                }
            }

            for contract_name_object in contract_name_objects {
                let contract_string =
                    data.substring(contract_name_object.start, contract_name_object.end);

                let constructor_string =
                    match per_contract_match_constructor.captures(contract_string) {
                        Some(found) => match found.get(1) {
                            Some(constructor) => {
                                let result = constructor.as_str().trim();
                                if result.eq("") {
                                    None
                                } else {
                                    Some(result.to_string())
                                }
                            }
                            None => None,
                        },
                        None => None,
                    };

                let parsable_constructor_string =
                    constructor_string.clone().unwrap_or("".to_string());

                // println!(
                //     "{} {}",
                //     contract_name_object.name, parsable_constructor_string
                // );

                let args: Vec<ConstructorArgObject> = if parsable_constructor_string.eq("") {
                    Vec::new()
                } else {
                    let args_split = parsable_constructor_string.split(",");
                    args_split
                        .map(|s| {
                            let components = s
                                .trim()
                                .split(" ")
                                .map(|v| v.to_string())
                                .collect::<Vec<String>>();

                            let mut args_type = components.get(0).unwrap().to_string();

                            let custom_type = is_custom_type(&args_type);

                            let second = components.get(1).unwrap();
                            let mut memory_type = false;
                            if second.eq("memory") {
                                memory_type = true;
                            }

                            let name = if memory_type {
                                components.get(2).unwrap()
                            } else {
                                if args_type.eq("address") && second.eq("payable") {
                                    args_type = format!("{} payable", args_type);
                                    components.get(2).unwrap()
                                } else {
                                    second
                                }
                            };

                            return ConstructorArgObject {
                                name: name.to_string(),
                                memory_type,
                                r#type: args_type,
                                custom_type,
                            };
                        })
                        .collect()
                };

                // println!("{} {:?}", contract_name_object.name, args);

                let solidity_filepath = entry.path().to_slash().unwrap().to_string();
                let solidity_filepath = solidity_filepath.substring(2, solidity_filepath.len());
                let contract = ContractObject {
                    solidity_filepath: String::from(solidity_filepath),
                    contract_name: String::from(contract_name_object.name),
                    solidity_filename: String::from(entry.file_name().to_str().unwrap()),
                    constructor: ConstructorObject { args },
                };
                // println!("{:?}", contract);
                contracts.push(contract);
            }
        }
    }
    // return ContractsInfo { imports, contracts };
    return contracts;
}
