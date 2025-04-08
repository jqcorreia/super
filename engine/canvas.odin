package engine

import wl "../wayland-odin/wayland"
import "core:fmt"
import "vendor:egl"

import "base:runtime"
import "core:c"

Canvas :: struct {
	width:       i32,
	height:      i32,
	surface:     ^wl.wl_surface,
	egl_surface: egl.Surface,
	xdg_surface: ^wl.xdg_surface,
}

surface_listener := wl.xdg_surface_listener {
	configure = surface_configure,
}

surface_configure :: proc "c" (data: rawptr, surface: ^wl.xdg_surface, serial: c.uint32_t) {
	context = runtime.default_context()
	fmt.println("surface_configure")
	canvas := cast(^Canvas)data
	fmt.println(canvas)

	wl.xdg_surface_ack_configure(surface, serial)
	wl.wl_surface_damage(canvas.surface, 0, 0, c.INT32_MAX, c.INT32_MAX)
	wl.wl_surface_commit(canvas.surface)
}

create_canvas :: proc(state: ^State, width: i32, height: i32) -> ^Canvas {
	canvas := new(Canvas)
	canvas.width = width
	canvas.height = height
	canvas.surface = wl.wl_compositor_create_surface(state.compositor)

	if canvas.surface == nil {
		fmt.println("Error creating surface")
		return canvas
	}

	egl_window := wl.egl_window_create(canvas.surface, width, height)
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

	canvas.egl_surface = egl_surface

	canvas.xdg_surface = wl.xdg_wm_base_get_xdg_surface(state.xdg_base, canvas.surface)
	toplevel := wl.xdg_surface_get_toplevel(canvas.xdg_surface)
	wl.xdg_toplevel_set_title(toplevel, "Odin Wayland")
	fmt.println("Canvas", canvas)
	wl.xdg_surface_add_listener(canvas.xdg_surface, &surface_listener, canvas)

	return canvas
}

add_listener :: proc(canvas: ^Canvas) {
	wl.xdg_surface_add_listener(canvas.xdg_surface, &surface_listener, canvas)
}
