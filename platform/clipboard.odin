package platform

import wl "../vendor/wayland-odin/wayland"
import "base:runtime"
import "core:c"
import "core:fmt"

data_source_listener := wl.wl_data_source_listener {
	target = proc "c" (data: rawptr, wl_data_source: ^wl.wl_data_source, mime_type: cstring) {
		context = runtime.default_context()
		fmt.println("send")
	},
	send = proc "c" (
		data: rawptr,
		wl_data_source: ^wl.wl_data_source,
		mime_type: cstring,
		fd: c.int32_t,
	) {
		context = runtime.default_context()
		fmt.println("send")
	},
	cancelled = proc "c" (data: rawptr, wl_data_source: ^wl.wl_data_source) {},
	dnd_drop_performed = proc "c" (data: rawptr, wl_data_source: ^wl.wl_data_source) {},
	dnd_finished = proc "c" (data: rawptr, wl_data_source: ^wl.wl_data_source) {},
	action = proc "c" (
		data: rawptr,
		wl_data_source: ^wl.wl_data_source,
		dnd_action: c.uint32_t,
	) {},
}

init_clipboard :: proc(pl: ^PlatformState) {
	fmt.println("Initializing clipboard controller")

	data_device := wl.wl_data_device_manager_get_data_device(pl.data_device_manager, pl.seat)
	data_source := wl.wl_data_device_manager_create_data_source(pl.data_device_manager)

	wl.wl_data_source_add_listener(data_source, &data_source_listener, nil)
	wl.wl_data_source_offer(data_source, "text/plain")

	wl.wl_data_device_set_selection(data_device, data_source, 100000)
	wl.display_roundtrip(pl.display)
}
