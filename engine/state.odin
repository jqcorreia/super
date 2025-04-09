package engine

import "../render"
import wl "../wayland-odin/wayland"

import "core:c"
import "core:fmt"
import "core:time"

import "base:runtime"
import gl "vendor:OpenGL"
import "vendor:egl"

State :: struct {
	display:             ^wl.wl_display,
	compositor:          ^wl.wl_compositor,
	xdg_base:            ^wl.xdg_wm_base,
	zwlr_layer_shell_v1: ^wl.zwlr_layer_shell_v1,
	seat:                ^wl.wl_seat,
	egl_render_context:  render.RenderContext,
	egl_surface:         egl.Surface,
	shader_programs:     map[string]u32,
	output:              ^wl.wl_output,
	start_time:          time.Time,
	time_elapsed:        time.Duration,
}

global :: proc "c" (
	data: rawptr,
	registry: ^wl.wl_registry,
	name: c.uint32_t,
	interface: cstring,
	version: c.uint32_t,
) {
	// context = runtime.default_context()
	if interface == wl.wl_compositor_interface.name {
		state: ^State = cast(^State)data
		state.compositor =
		cast(^wl.wl_compositor)(wl.wl_registry_bind(
				registry,
				name,
				&wl.wl_compositor_interface,
				version,
			))
	}

	if interface == wl.xdg_wm_base_interface.name {
		state: ^State = cast(^State)data
		state.xdg_base =
		cast(^wl.xdg_wm_base)(wl.wl_registry_bind(
				registry,
				name,
				&wl.xdg_wm_base_interface,
				version,
			))
	}
	if interface == wl.zwlr_layer_shell_v1_interface.name {
		state: ^State = cast(^State)data
		state.zwlr_layer_shell_v1 =
		cast(^wl.zwlr_layer_shell_v1)(wl.wl_registry_bind(
				registry,
				name,
				&wl.zwlr_layer_shell_v1_interface,
				version,
			))
	}
	if interface == wl.wl_seat_interface.name {
		state: ^State = cast(^State)data
		state.seat =
		cast(^wl.wl_seat)(wl.wl_registry_bind(registry, name, &wl.wl_seat_interface, version))
	}
}

global_remove :: proc "c" (data: rawptr, registry: ^wl.wl_registry, name: c.uint32_t) {
}

registry_listener := wl.wl_registry_listener {
	global        = global,
	global_remove = global_remove,
}

keyboard_listener := wl.wl_keyboard_listener {
	keymap = proc "c" (
		data: rawptr,
		keyboard: ^wl.wl_keyboard,
		format: c.uint32_t,
		fd: c.int32_t,
		size: c.uint32_t,
	) {
	},
	enter = proc "c" (
		data: rawptr,
		keyboard: ^wl.wl_keyboard,
		serial: c.uint32_t,
		surface: ^wl.wl_surface,
		keys: ^wl.wl_array,
	) {
	},
	leave = proc "c" (
		data: rawptr,
		keyboard: ^wl.wl_keyboard,
		serial: c.uint32_t,
		surface: ^wl.wl_surface,
	) {
	},
	key = proc "c" (
		data: rawptr,
		keyboard: ^wl.wl_keyboard,
		serial: c.uint32_t,
		time: c.uint32_t,
		key: c.uint32_t,
		state: c.uint32_t,
	) {
		// context = runtime.default_context()
		// fmt.println("Key pressed: ", key, " state: ", state)
	},
	modifiers = proc "c" (
		data: rawptr,
		wl_keyboard: ^wl.wl_keyboard,
		serial: c.uint32_t,
		mods_depressed: c.uint32_t,
		mods_latched: c.uint32_t,
		mods_locked: c.uint32_t,
		group: c.uint32_t,
	) {
	},
	repeat_info = proc "c" (
		data: rawptr,
		wl_keyboard: ^wl.wl_keyboard,
		rate: c.int32_t,
		delay: c.int32_t,
	) {},
}

init :: proc(width: i32, height: i32) -> State {
	state: State = {}

	state.start_time = time.now()
	display := wl.display_connect(nil)
	state.display = display

	// Get registry, add a global listener and get things started
	// Do a roundtrip in order to get registry info and populate the wayland part of state
	registry := wl.wl_display_get_registry(display)
	wl.wl_registry_add_listener(registry, &registry_listener, &state)
	wl.display_roundtrip(display)

	// Initialize EGL and OpenGL
	rctx := render.init_egl(display)
	state.egl_render_context = rctx

	//TODO(quadrado): Properly understand this and document it
	// This somehow loads the proper function pointers or something...
	gl.load_up_to(int(3), 2, egl.gl_set_proc_address)

	// surface := create_surface(&state, width, height)
	// state.surface = surface.surface

	// keyboard := wl.wl_seat_get_keyboard(state.seat)
	// wl.wl_keyboard_add_listener(keyboard, &keyboard_listener, nil)

	return state
}
