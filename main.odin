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

draw :: proc(canvas: ^engine.Canvas, state: ^engine.State) {
	// if (!egl.MakeCurrent(
	// 		   state.egl_render_context.display,
	// 		   canvas.egl_surface,
	// 		   canvas.egl_surface,
	// 		   state.egl_render_context.ctx,
	// 	   )) {
	// 	fmt.println("Error making current!")
	// }
	shader := state.shader_programs["Singularity"]

	gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
	// gl.ClearColor(0.0, 0.0, 0.0, 0.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	p.draw_rect(0, 0, 800, 600, shader, state)
	gl.Flush()

	// egl.SwapBuffers(state.egl_render_context.display, canvas.egl_surface)
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

	// canvas2 := engine.create_canvas(&state, WIDTH, HEIGHT, engine.CanvasType.Layer)
	// engine.set_draw_callback(&state, canvas2, draw)

	state.shader_programs["Basic"] = load_shader(
		"shaders/basic_vert.glsl",
		"shaders/basic_frag.glsl",
	)

	state.shader_programs["Singularity"] = load_shader(
		"shaders/basic_vert.glsl",
		"shaders/singularity.glsl",
	)

	for {
		state.time_elapsed = time.diff(state.start_time, time.now())
		wl.display_dispatch(state.display)
		egl.SwapBuffers(state.egl_render_context.display, canvas.egl_surface)
	}
}
