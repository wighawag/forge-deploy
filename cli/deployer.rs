use std::{fs, path::Path, path::PathBuf};

use handlebars::Handlebars;

use crate::types::ContractObject;

pub fn generate_deployer(
    contracts: &Vec<ContractObject>,
    extra_templates_path: &Vec<PathBuf>,
    generated_folder: &str,
) {
    let mut handlebars = Handlebars::new();
    handlebars.set_strict_mode(true);
    handlebars.register_helper("memory-type", Box::new(memory_type));

    handlebars
        .register_template_string(
            "DeployerFunctions.g.sol",
            include_str!("templates/DeployerFunctions.g.sol.hbs"),
        )
        .unwrap();

    let mut templates: Vec<String> = Vec::new();
    for template_path in extra_templates_path {
        if template_path.is_dir() {
            for file in fs::read_dir(template_path).unwrap() {
                match file {
                    Ok(file) => {
                        if file.metadata().unwrap().is_file() {
                            let template_sub_path = file.path();
                            let content = fs::read_to_string(&template_sub_path).expect(&format!(
                                "Failed to read template {}",
                                template_sub_path.display()
                            ));
                            let template_name = template_name(&template_sub_path);
                            handlebars
                                .register_template_string(&template_name, content)
                                .unwrap();
                            templates.push(template_name);
                            // TODO avoid duplicate or let them override ?
                        }
                    }
                    Err(e) => eprintln!("{}", e),
                }
            }
        } else {
            let content = fs::read_to_string(&template_path).expect(&format!(
                "Failed to read template {}",
                template_path.display()
            ));
            let template_name = template_name(&template_path);
            handlebars
                .register_template_string(&template_name, content)
                .unwrap();
            templates.push(template_name);
        }
    }

    let folder_path_buf = Path::new(generated_folder).join("deployer");
    let folder_path = folder_path_buf.to_str().unwrap();

    fs::create_dir_all(folder_path).expect("create folder");

    write_if_different(
        &format!("{}/DeployerFunctions.g.sol", folder_path),
        format!(
            "{}",
            handlebars
                .render("DeployerFunctions.g.sol", contracts)
                .unwrap()
        ),
    );

    // for template_path in extra_templates_path {
    //     let template_name = template_name(&template_path);
    //     write_if_different(
    //         &format!("{}/{}", folder_path, template_name),
    //         format!("{}", handlebars.render(&template_name, contracts).unwrap()),
    //     );
    // }
    for template in templates {
        write_if_different(
            &format!("{}/{}", folder_path, template),
            format!("{}", handlebars.render(&template, contracts).unwrap()),
        );
    }
}

fn write_if_different(path: &String, content: String) {
    // let bytes_to_write = content.as_bytes();

    let result = fs::read(path);
    let same = match result {
        Ok(existing) => String::from_utf8(existing).unwrap().eq(&content),
        Err(_e) => false,
    };

    if !same {
        println!("writing new files...");
        fs::write(path, content).expect("could not write file");
    }
}

use handlebars::{Context, Helper, HelperResult, JsonRender, Output, RenderContext};

fn memory_type(
    h: &Helper,
    _: &Handlebars,
    _: &Context,
    _rc: &mut RenderContext,
    out: &mut dyn Output,
) -> HelperResult {
    let param = h.param(0).unwrap();

    let str_value = param.value().render();
    if str_value.eq("string") {
        out.write("memory")?;
    }

    Ok(())
}

fn template_name(template_path: &PathBuf) -> String {
    let filename = template_path
        .file_name()
        .unwrap()
        .to_str()
        .unwrap()
        .to_string();
    let filename = if filename.ends_with(".hbs") {
        filename.strip_suffix(".hbs").unwrap().to_string()
    } else {
        filename
    };
    if !filename.ends_with(".sol") {
        format!("{}.sol", filename)
    } else {
        filename
    }
}
