package actions

import "../engine"
import "core:encoding/ini"
import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:strings"

Action :: union {
	ApplicationAction,
	SecretAction,
}

ApplicationAction :: struct {
	name:    string,
	icon:    u32,
	command: string,
}

SecretAction :: struct {
	name: string,
	icon: u32,
}

get_application_actions :: proc() -> []Action {
	applications: [dynamic]Action
	paths: [dynamic]string = {}
	home := os.get_env("HOME")
	xdg_data_dirs, ok := os.lookup_env("XDG_DATA_DIRS")

	if ok {
		for base_data in strings.split(xdg_data_dirs, ":") {
			append(&paths, fmt.tprintf("%s/applications", base_data))
		}
	} else {
		append(&paths, fmt.tprintf("%s/.local/share/applications", home))
		append(&paths, "/usr/share/applications")
	}


	for path in paths {
		// List dir files
		h, _ := os.open(path)
		fis, _ := os.read_dir(h, -1)

		for fi in fis {
			res, _, _ := ini.load_map_from_path(fi.fullpath, context.temp_allocator)

			de, ok_entry := res["Desktop Entry"]
			if ok_entry {
				name, _ := de["Name"]
				exec, _ := de["Exec"]
				append(&applications, ApplicationAction{name = name, command = exec})
			}
		}
	}

	return applications[:]
}

do_application_action :: proc(action: ApplicationAction) {
	// This removes the XDG placeholders like %F and %U and all that crap that we dont care
	// At least we don't care right now...
	clean_command := strings.trim(strings.split(action.command, "%")[0], " \n")
	p, e := os2.process_start({command = strings.split(clean_command, " ")})

	fmt.println(p, e)

	engine.state.running = false
}

do_secret_action :: proc(action: SecretAction) {
	// This weird dance is needed for 2 reasons
	// - There is no way of knowing if a pass secret is otp unless you decode it first and check
	// - If you call process_exec with wl-copy, given that it is a process that doesn't exit, we just hang
	// - Do the check and call the process_start() that doesn't hang and let wl-copy do it's thing
	pass_command := []string{"sh", "-c", fmt.tprintf("pass %s", action.name)}
	_, out, _, _ := os2.process_exec({command = pass_command}, context.allocator)

	out_s := string(out)
	if strings.starts_with(out_s, "otpauth://") {
		pass_command_otp := []string{"sh", "-c", fmt.tprintf("pass otp %s", action.name)}
		_, out_otp, _, _ := os2.process_exec({command = pass_command_otp}, context.allocator)
		_, _ = os2.process_start({command = {"wl-copy", strings.trim(string(out_otp), "\n")}})
	} else {
		_, _ = os2.process_start({command = {"wl-copy", strings.trim(string(out_s), "\n")}})
	}

	engine.state.running = false
}

get_secret_actions :: proc() -> []Action {
	secrets: [dynamic]Action

	secrets_path := fmt.tprintf("%s/.password-store", os.get_env("HOME"))
	home, _ := os.open(secrets_path)
	fis, _ := os.read_dir(home, -1)

	for fi in fis {
		if strings.starts_with(fi.name, ".") {
			continue
		}
		secret_name := strings.split(fi.name, ".gpg")[0]
		append(&secrets, SecretAction{name = secret_name})
	}

	return secrets[:]
}

do_action :: proc(action: Action) {
	switch a in action {
	case ApplicationAction:
		{
			_do_action(a)
		}
	case SecretAction:
		{
			_do_action(a)
		}
	}
}

_do_action :: proc {
	do_application_action,
	do_secret_action,
}
