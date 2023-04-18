use std::{fs, path::Path};

use handlebars::Handlebars;

use crate::types::{ContractObject};

pub fn generate_deployer(contracts: &Vec<ContractObject>, generated_folder: &str) {
    for contract in contracts {
        println!("contract: {}", contract.contract_name);
    }

    let mut handlebars = Handlebars::new();
    handlebars.register_helper("memory-type", Box::new(memory_type));
    handlebars
        .register_template_string(
            "Deployer.g.sol",
            include_str!("templates/Deployer.g.sol.hbs"),
        )
        .unwrap();
    handlebars
        .register_template_string(
            "Artifacts.g.sol",
            include_str!("templates/Artifacts.g.sol.hbs"),
        )
        .unwrap();
    handlebars
        .register_template_string(
            "DeployScript.g.sol",
            include_str!("templates/DeployScript.g.sol.hbs"),
        )
        .unwrap();

    handlebars.set_strict_mode(true);

    let folder_path_buf = Path::new(generated_folder).join("deployer");
    let folder_path = folder_path_buf.to_str().unwrap();

    fs::create_dir_all(folder_path).expect("create folder");

    // fs::write(
    //     format!("{}/Deployer.g.sol", folder_path),
    //     format!(
    //         "{}",
    //         handlebars.render("Deployer.g.sol", artifacts).unwrap()
    //     ),
    // )
    // .expect("could not write file");
    // write_if_different(
    //     format!("{}/Artifacts.g.sol", folder_path),
    //     format!("{}",handlebars.render("Artifacts.g.sol", artifacts).unwrap()
    // );
    // fs::write(
    //     format!("{}/Artifacts.g.sol", folder_path),
    //     format!(
    //         "{}",
    //         handlebars.render("Artifacts.g.sol", artifacts).unwrap()
    //     ),
    // )
    // .expect("could not write file");

    // fs::write(
    //     format!("{}/DeployScript.g.sol", folder_path),
    //     format!(
    //         "{}",
    //         handlebars.render("DeployScript.g.sol", artifacts).unwrap()
    //     ),
    // )
    // .expect("could not write file");

    write_if_different(
        &format!("{}/Deployer.g.sol", folder_path), format!("{}",
        handlebars.render("Deployer.g.sol", contracts).unwrap())
    );
    write_if_different(
        &format!("{}/Artifacts.g.sol", folder_path), format!("{}",
        handlebars.render("Artifacts.g.sol", contracts).unwrap())
    );
    write_if_different(
        &format!("{}/DeployScript.g.sol", folder_path), format!("{}",
        handlebars.render("DeployScript.g.sol", contracts).unwrap())
    );


    

}


fn write_if_different(path: &String, content: String) {
    // let bytes_to_write = content.as_bytes();

    let result = fs::read(path);
    let same = match result {
        Ok(existing) => String::from_utf8(existing).unwrap().eq(&content),
        Err(_e) => false
    };

    if !same {
        println!("writing new files...");
        fs::write(path, content).expect("could not write file");
    }
    
}

use handlebars::{RenderContext, Helper, Context, HelperResult, Output, JsonRender};

fn memory_type (h: &Helper, _: &Handlebars, _: &Context, _rc: &mut RenderContext, out: &mut dyn Output) -> HelperResult {
    let param = h.param(0).unwrap();

    let str_value = param.value().render();
    if str_value.eq("string") {
        out.write("memory")?;
    }
    
    Ok(())
}