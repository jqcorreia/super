package state

import "core:c"
import "core:fmt"

import gl "vendor:OpenGL"
import "vendor:egl"

import "../render"
import wl "../wayland-odin/wayland"


State :: struct {
	display:             ^wl.wl_display,
	compositor:          ^wl.wl_compositor,
	xdg_base:            ^wl.xdg_wm_base,
	zwlr_layer_shell_v1: ^wl.zwlr_layer_shell_v1,
	shm:                 ^wl.wl_shm,
	surface:             ^wl.wl_surface,
	egl:                 struct {
		ctx:     egl.Context,
		display: egl.Display,
		surface: egl.Surface,
	},
	shader_program:      u32,
}

global :: proc "c" (
	data: rawptr,
	registry: ^wl.wl_registry,
	name: c.uint32_t,
	interface: cstring,
	version: c.uint32_t,
) {
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

	if interface == wl.wl_shm_interface.name {
		state: ^State = cast(^State)data
		state.shm =
		cast(^wl.wl_shm)(wl.wl_registry_bind(registry, name, &wl.wl_shm_interface, version))
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
}

global_remove :: proc "c" (data: rawptr, registry: ^wl.wl_registry, name: c.uint32_t) {
}

registry_listener := wl.wl_registry_listener {
	global        = global,
	global_remove = global_remove,
}

init :: proc() -> State {
	width: i32 = 800
	height: i32 = 600
	state: State = {}

	display := wl.display_connect(nil)
	state.display = display
	registry := wl.wl_display_get_registry(display)

	wl.wl_registry_add_listener(registry, &registry_listener, &state)

	// Do a roundtrip in order to get registry info and populate the wayland part of state
	wl.display_roundtrip(display)

	// Create the surface
	state.surface = wl.wl_compositor_create_surface(state.compositor)

	rctx := render.init_egl(display)

	egl_window := wl.egl_window_create(state.surface, width, height)
	egl_surface := egl.CreateWindowSurface(
		rctx.display,
		rctx.config,
		egl.NativeWindowType(egl_window),
		nil,
	)

	if egl_surface == egl.NO_SURFACE {
		fmt.println("Error creating window surface")

	}
	if (!egl.MakeCurrent(rctx.display, egl_surface, egl_surface, rctx.ctx)) {
		fmt.println("Error making current!")
	}

	gl.load_up_to(int(3), 2, egl.gl_set_proc_address)
	state.egl.display = rctx.display
	state.egl.ctx = rctx.ctx
	state.egl.surface = egl_surface

	return state
}
