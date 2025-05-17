package canvas

import pl "../../platform"
import wl "../../vendor/wayland-odin/wayland"
import "base:runtime"
import "core:c"
import "core:fmt"

window_listener := wl.xdg_surface_listener {
	configure = proc "c" (data: rawptr, surface: ^wl.xdg_surface, serial: c.uint32_t) {
		context = runtime.default_context()
		fmt.println("window configure")
		cc := cast(^CanvasCallback)data
		canvas := cc.canvas
		state := cc.platform_state

		wl.xdg_surface_ack_configure(surface, serial)
		wl.wl_surface_damage(canvas.surface, 0, 0, canvas.width, canvas.height)
		wl.wl_surface_commit(canvas.surface)
	},
}

toplevel_listener := wl.xdg_toplevel_listener {
	configure = proc "c" (
		data: rawptr,
		xdg_toplevel: ^wl.xdg_toplevel,
		width: c.int32_t,
		height: c.int32_t,
		states: ^wl.wl_array,
	) {
		context = runtime.default_context()
		fmt.println("Top level configure", width, height, states)
		cc := cast(^CanvasCallback)data
		canvas := cc.canvas
		egl_render_context := cc.platform_state.egl_render_context
		// if canvas.width != width ||
		//    canvas.height != height && (canvas.width > 0 && canvas.height > 0) {
		// 	resize_egl_window(canvas, egl_render_context, i32(width), i32(height))
		// }
		canvas.ready = true
	},
	close = proc "c" (data: rawptr, xdg_toplevel: ^wl.xdg_toplevel) {},
	configure_bounds = proc "c" (
		data: rawptr,
		xdg_toplevel: ^wl.xdg_toplevel,
		width: c.int32_t,
		height: c.int32_t,
	) {
		context = runtime.default_context()
		fmt.println("Top level configure bounds", width, height)

	},
	wm_capabilities = proc "c" (
		data: rawptr,
		xdg_toplevel: ^wl.xdg_toplevel,
		capabilities: ^wl.wl_array,
	) {},
}

init_window_canvas :: proc(cc: ^CanvasCallback) {
	canvas := cc.canvas
	platform := cc.platform_state

	create_egl_window(canvas, platform.egl_render_context, canvas.width, canvas.height)

	if (!cc.platform_state.default_shaders_loaded) {
		pl.create_default_shaders()
		cc.platform_state.default_shaders_loaded = true
	}

	xdg_surface := wl.xdg_wm_base_get_xdg_surface(platform.xdg_base, canvas.surface)
	toplevel := wl.xdg_surface_get_toplevel(xdg_surface)
	wl.xdg_toplevel_add_listener(toplevel, &toplevel_listener, cc)
	wl.xdg_toplevel_set_title(toplevel, "super")
	wl.xdg_toplevel_set_app_id(toplevel, "modal-float")
	wl.xdg_toplevel_set_parent(toplevel, nil)
	wl.xdg_surface_add_listener(xdg_surface, &window_listener, cc)
	wl.xdg_toplevel_set_max_size(toplevel, 800, 600)
	wl.xdg_toplevel_set_min_size(toplevel, 800, 600)

	// wl.xdg_surface_set_window_geometry(xdg_surface, 100, 100, 100, 100)
}
