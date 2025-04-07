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
	shm:                 ^wl.wl_shm,
	surface:             ^wl.wl_surface,
	egl:                 struct {
		ctx:     egl.Context,
		display: egl.Display,
		surface: egl.Surface,
	},
	egl_render_context:  render.RenderContext,
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

	// if interface == wl.wl_output_interface.name {
	// 	fmt.println("Found output")
	// 	state: ^State = cast(^State)data
	// 	if state.output != nil {
	// 		fmt.println("Output already set")
	// 		return
	// 	}

	// 	state.output =
	// 	cast(^wl.wl_output)(wl.wl_registry_bind(registry, name, &wl.wl_output_interface, version))
	// }

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

	// Create the surface
	state.surface = wl.wl_compositor_create_surface(state.compositor)

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

	state.egl.display = rctx.display
	state.egl.ctx = rctx.ctx
	state.egl.surface = egl_surface

	return state
}

create_surface :: proc(state: ^State, width: i32, height: i32) -> Surface {
	surface: Surface = {}
	surface.width = width
	surface.height = height
	surface.surface = wl.wl_compositor_create_surface(state.compositor)

	if surface.surface == nil {
		fmt.println("Error creating surface")
		return surface
	}

	egl_window := wl.egl_window_create(state.surface, width, height)
	egl_surface := egl.CreateWindowSurface(
		state.egl_render_context.display,
		state.egl_render_context.config,
		egl.NativeWindowType(egl_window),
		nil,
	)

	if egl_surface == egl.NO_SURFACE {
		fmt.println("Error creating window surface")

	}
	if (!egl.MakeCurrent(
			   state.egl_render_context.display,
			   egl_surface,
			   egl_surface,
			   state.egl_render_context.ctx,
		   )) {
		fmt.println("Error making current!")
	}


	return surface
}
