package actions

import "../engine"
import "core:os"
import "core:strings"

BluetoothAction :: struct {
	name:      string,
	address:   string,
	connected: bool,
}

// Parses `bluetoothctl devices <filter>` output, lines look like "Device XX:XX:XX:XX:XX:XX Name"
@(private)
bluetooth_list_devices :: proc(filter: string) -> map[string]string {
	devices: map[string]string

	state, out, _, err := os.process_exec(
		{command = {"bluetoothctl", "devices", filter}},
		context.allocator,
	)
	if err != nil || !state.success {
		return devices
	}

	for line in strings.split_lines(string(out)) {
		if !strings.has_prefix(line, "Device ") {
			continue
		}
		parts := strings.split_n(line, " ", 3)
		if len(parts) < 3 {
			continue
		}
		devices[parts[1]] = parts[2]
	}

	return devices
}

get_bluetooth_actions :: proc() -> []Action {
	actions: [dynamic]Action

	paired := bluetooth_list_devices("Paired")
	connected := bluetooth_list_devices("Connected")

	for address, name in paired {
		append(
			&actions,
			BluetoothAction{name = name, address = address, connected = address in connected},
		)
	}

	return actions[:]
}

do_bluetooth_action :: proc(action: BluetoothAction) {
	// Connecting can take a few seconds, so don't wait for it
	command := action.connected ? "disconnect" : "connect"
	_, _ = os.process_start({command = {"bluetoothctl", command, action.address}})

	engine.state.running = false
}
