package main

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:time"

import "engine"
import "render"
import p "render/primitives"
import gl "vendor:OpenGL"
import "vendor:egl"
import wl "wayland-odin/wayland"


done :: proc "c" (data: rawptr, wl_callback: ^wl.wl_callback, callback_data: c.uint32_t) {
	context = runtime.default_context()
	canvas := cast(^engine.Canvas)data
	fmt.println("-----------_", canvas)
	wl_callback_destroy(wl_callback)
	callback := wl.wl_surface_frame(canvas.surface)
	wl.wl_callback_add_listener(callback, &frame_callback_listener, canvas)

	// Maybe render code goes here
	// draw(state)
	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	// gl.ClearColor(0.0, 0.0, 0.0, 0.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	gl.Flush()
}

frame_callback_listener := wl.wl_callback_listener {
	done = done,
}

// This should be generated once this whole thing works
wl_callback_destroy :: proc "c" (wl_callback: ^wl.wl_callback) {
	wl.proxy_destroy(cast(^wl.wl_proxy)wl_callback)
}


draw :: proc(state: ^engine.State) {
	shader := state.shader_programs["Singularity"]

	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	// gl.ClearColor(0.0, 0.0, 0.0, 0.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	p.draw_rect(0, 0, 800, 600, shader, state)
	gl.Flush()
}

load_shader :: proc(vertex_shader_path: string, fragment_shader_path: string) -> u32 {
	shaders, result := gl.load_shaders_file(vertex_shader_path, fragment_shader_path)

	fmt.println(result)
	return shaders
}

WIDTH :: 800
HEIGHT :: 600

main :: proc() {
	state := engine.init(WIDTH, HEIGHT)
	canvas := engine.create_canvas(&state, WIDTH, HEIGHT, engine.CanvasType.Window)
	engine.set_draw_callback(&state, canvas, draw)

	state.shader_programs["Basic"] = load_shader(
		"shaders/basic_vert.glsl",
		"shaders/basic_frag.glsl",
	)

	state.shader_programs["Singularity"] = load_shader(
		"shaders/basic_vert.glsl",
		"shaders/singularity.glsl",
	)

	// wl_callback := wl.wl_surface_frame(canvas.surface)
	// wl.wl_callback_add_listener(wl_callback, &frame_callback_listener, canvas)
	// wl.wl_surface_commit(canvas.surface)

	for {
		state.time_elapsed = time.diff(state.start_time, time.now())
		wl.display_dispatch(state.display)
		egl.SwapBuffers(state.egl_render_context.display, canvas.egl_surface)
	}
}
