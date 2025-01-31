package main

import "core:c"
import "core:c/libc"
import "core:fmt"
import "render"
import wl "wayland-odin/wayland"

import "core:sys/posix"

import "base:runtime"
import gl "vendor:OpenGL"
import "vendor:egl"

import "state"

surface_listener := wl.xdg_surface_listener {
	configure = surface_configure,
}

buffer_listener := wl.wl_buffer_listener {
	release = proc "c" (data: rawptr, wl_buffer: ^wl.wl_buffer) {
		wl.wl_buffer_destroy(wl_buffer)
	},
}

done :: proc "c" (data: rawptr, wl_callback: ^wl.wl_callback, callback_data: c.uint32_t) {
	context = runtime.default_context()
	state := cast(^state.State)data

	// Maybe render code goes here
	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	gl.Flush()
	egl.SwapBuffers(state.egl.display, state.egl.surface)
}

frame_callback_listener := wl.wl_callback_listener {
	done = done,
}

surface_configure :: proc "c" (data: rawptr, surface: ^wl.xdg_surface, serial: c.uint32_t) {
	//context = runtime.default_context()
	state := cast(^state.State)data
	//
	//fmt.println("surface configure")
	//wl.xdg_surface_ack_configure(surface, serial)
	//
	//buffer := get_buffer(state, 800, 600)
	//wl.wl_surface_attach(state.surface, buffer, 0, 0)
	wl.wl_surface_damage(state.surface, 0, 0, c.INT32_MAX, c.INT32_MAX)
	wl.wl_surface_commit(state.surface)
}

// This should be generated once this whole thing works
wl_callback_destroy :: proc "c" (wl_callback: ^wl.wl_callback) {
	wl.proxy_destroy(cast(^wl.wl_proxy)wl_callback)
}

main :: proc() {
	using state
	state := init_state()

	fmt.println(state)
	xdg_surface := wl.xdg_wm_base_get_xdg_surface(state.xdg_base, state.surface)
	toplevel := wl.xdg_surface_get_toplevel(xdg_surface)
	wl.xdg_toplevel_set_title(toplevel, "Odin Wayland")

	wl.wl_surface_commit(state.surface) // This first commit is needed by egl or egl.SwapBuffers() will panic
	wl.xdg_surface_add_listener(xdg_surface, &surface_listener, &state)


	// // EGL initialization stuff
	// rctx := render.init_egl(display)
	// egl_window := wl.egl_window_create(state.surface, 800, 600)
	// egl_surface := egl.CreateWindowSurface(
	// 	rctx.display,
	// 	rctx.config,
	// 	egl.NativeWindowType(egl_window),
	// 	nil,
	// )

	// if egl_surface == egl.NO_SURFACE {
	// 	fmt.println("Error creating window surface")
	// 	return

	// }
	// if (!egl.MakeCurrent(rctx.display, egl_surface, egl_surface, rctx.ctx)) {
	// 	fmt.println("Error making current!")
	// 	return
	// }
	// gl.load_up_to(int(1), 5, egl.gl_set_proc_address)


	wl_callback := wl.wl_surface_frame(state.surface)
	wl.wl_callback_add_listener(wl_callback, &frame_callback_listener, &state)
	wl.wl_surface_commit(state.surface)

	for {
		wl.display_dispatch(state.display)
	}
}
