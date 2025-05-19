package xdg

import "core:os"

icon_map := map[string]Icon

Icon :: struct {}


@(init)
generate_icon_map :: proc() {
	home := os.get_env("HOME")
	xdg_data_dirs := os.lookup_env("XDG_DATA_DIRS") or_else fmt.tprintf("%s/.local/share", home)
	//let home = std::env::var("HOME").unwrap();
	//let mut map: HashMap<IconConfig, String> = HashMap::new();
	//let mut sizes: HashSet<u32> = HashSet::new();

	//let env_folders = std::env::var("XDG_DATA_DIRS")
	//    .unwrap_or(format!("/usr/share:{}/.local/share", home).to_string());

	//let base_folders = env_folders.split(":");

	//let mut themes = vec!["hicolor".to_string()];

	//if let Some(theme_name) = get_gtk_settings_theme() {
	//    themes.push(theme_name);
	//}
	//for theme in themes {
	//    // Try to find and parse the index.theme file for the theme being processed
	//    for base_folder in base_folders.clone() {
	//        let path = format!("{}/icons/{}/index.theme", base_folder, theme);

	//        let ini: IniMap = match parse_ini_file(path.clone()) {
	//            Ok(i) => i,
	//            Err(_) => continue,
	//        };

	//        let dirs: Vec<String> = ini
	//            .get("Icon Theme")
	//            .unwrap()
	//            .get("Directories")
	//            .unwrap()
	//            .split(",")
	//            .map(|x| x.to_string())
	//            .filter(|x| !x.is_empty())
	//            .collect();

	//        // Traverse the base_folders again to include all the icons that may exist for this theme
	//        for base_folder in base_folders.clone() {
	//            for dir in dirs.iter() {
	//                if ini.get(dir).is_none() {
	//                    debug!("Section {} not found", dir);
	//                    continue;
	//                }
	//                let section = ini.get(dir).unwrap();
	//                let size: u32 = section.get("Size").unwrap().parse().unwrap();
	//                let scale = section.get("Scale").map_or("1", |v| v);

	//                if scale.parse::<u32>().unwrap() > 1 {
	//                    //FIXME(quadrado): For now ignore scaled icons
	//                    continue;
	//                }
	//                sizes.insert(size);

	//                let d = format!("{}/icons/{}/{}", base_folder, theme, dir);
	//                if let Ok(files) = fs::read_dir(d) {
	//                    for file in files {
	//                        let fpath =
	//                            file.unwrap().path().into_os_string().into_string().unwrap();

	//                        let fname_no_ext = std::path::Path::new(&fpath)
	//                            .file_stem()
	//                            .unwrap()
	//                            .to_os_string()
	//                            .to_str()
	//                            .unwrap()
	//                            .to_string();

	//                        //fpath.split("/").last().unwrap().split(".").next().unwrap();

	//                        // println!("{} {}", fname_no_ext, fpath);
	//                        let icon_config = IconConfig {
	//                            size,
	//                            name: fname_no_ext,
	//                        };
	//                        map.insert(icon_config, fpath);
	//                    }
	//                }
	//            }
	//        }
	//        // index.theme found and processed, can exit now
	//        break;
	//    }
	//}

	//// Process /usr/share/pixmaps
	//if let Ok(files) = fs::read_dir("/usr/share/pixmaps/") {
	//    for file in files {
	//        if file.as_ref().unwrap().file_type().unwrap().is_dir() {
	//            continue;
	//        }
	//        let fpath = file.unwrap().path().into_os_string().into_string().unwrap();
	//        let fname_no_ext = fpath.split("/").last().unwrap().split(".").next().unwrap();

	//        let icon_config = IconConfig {
	//            size: 32, //FIXME(quadrado): Don't use this fixed size that means nothing. Need
	//            //to open the image and calculate the proper size.
	//            name: fname_no_ext.to_string(),
	//        };
	//        map.insert(icon_config, fpath);
	//    }
	//}

	//(map, sizes)
}
