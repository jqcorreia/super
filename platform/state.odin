package platform

import wl "../vendor/wayland-odin/wayland"
import "core:c"
import gl "vendor:OpenGL"
import "vendor:egl"

PlatformState :: struct {
	display:             ^wl.wl_display,
	compositor:          ^wl.wl_compositor,
	xdg_base:            ^wl.xdg_wm_base,
	zwlr_layer_shell_v1: ^wl.zwlr_layer_shell_v1,
	seat:                ^wl.wl_seat,
	egl_render_context:  RenderContext,
	egl_surface:         egl.Surface,
	input:               ^Input,
	shaders:             Shaders,
	xkb:                 Xkb,
}

registry_listener := wl.wl_registry_listener {
	global        = global,
	global_remove = global_remove,
}

global :: proc "c" (
	data: rawptr,
	registry: ^wl.wl_registry,
	name: c.uint32_t,
	interface: cstring,
	version: c.uint32_t,
) {
	if interface == wl.wl_compositor_interface.name {
		state: ^PlatformState = cast(^PlatformState)data
		state.compositor =
		cast(^wl.wl_compositor)(wl.wl_registry_bind(
				registry,
				name,
				&wl.wl_compositor_interface,
				version,
			))
	}

	if interface == wl.xdg_wm_base_interface.name {
		state: ^PlatformState = cast(^PlatformState)data
		state.xdg_base =
		cast(^wl.xdg_wm_base)(wl.wl_registry_bind(
				registry,
				name,
				&wl.xdg_wm_base_interface,
				version,
			))
	}
	if interface == wl.zwlr_layer_shell_v1_interface.name {
		state: ^PlatformState = cast(^PlatformState)data
		state.zwlr_layer_shell_v1 =
		cast(^wl.zwlr_layer_shell_v1)(wl.wl_registry_bind(
				registry,
				name,
				&wl.zwlr_layer_shell_v1_interface,
				version,
			))
	}
	if interface == wl.wl_seat_interface.name {
		state: ^PlatformState = cast(^PlatformState)data
		state.seat =
		cast(^wl.wl_seat)(wl.wl_registry_bind(registry, name, &wl.wl_seat_interface, version))
	}
}

global_remove :: proc "c" (data: rawptr, registry: ^wl.wl_registry, name: c.uint32_t) {
}

init_platform :: proc() -> ^PlatformState {
	state := new(PlatformState)
	display := wl.display_connect(nil)
	state.display = display

	// Get registry, add a global listener and get things started
	// Do a roundtrip in order to get registry info and populate the wayland part of state
	registry := wl.wl_display_get_registry(display)
	wl.wl_registry_add_listener(registry, &registry_listener, state)
	wl.display_roundtrip(display)


	// Initialize EGL and OpenGL
	rctx := init_egl(display)
	state.egl_render_context = rctx

	//TODO(quadrado): Properly understand this and document it
	// This somehow loads the proper function pointers or something...
	gl.load_up_to(int(3), 2, egl.gl_set_proc_address)

	// Initialize input controller
	init_input(state)

	// Initialize shaders controller
	state.shaders = create_shaders_controller()
	return state
}
