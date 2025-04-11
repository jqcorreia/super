package engine

import wl "../wayland-odin/wayland"
import "core:fmt"
import "vendor:egl"

import "base:runtime"
import "core:c"

DrawProc :: proc(_: ^Canvas, _: ^State)

Canvas :: struct {
	width:       i32,
	height:      i32,
	surface:     ^wl.wl_surface,
	egl_surface: egl.Surface,
	draw:        DrawProc,
}

CanvasType :: enum {
	Layer,
	Window,
}

CanvasCallback :: struct {
	state:  ^State,
	canvas: ^Canvas,
}

ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP :: 2
ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM :: 2
ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT :: 4
ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT :: 8

window_listener := wl.xdg_surface_listener {
	configure = proc "c" (data: rawptr, surface: ^wl.xdg_surface, serial: c.uint32_t) {
		context = runtime.default_context()
		// fmt.println("surface_configure")
		canvas := cast(^Canvas)data
		// fmt.println(canvas)

		wl.xdg_surface_ack_configure(surface, serial)
		wl.wl_surface_damage(canvas.surface, 0, 0, c.INT32_MAX, c.INT32_MAX)
		wl.wl_surface_commit(canvas.surface)
	},
}

layer_listener := wl.zwlr_layer_surface_v1_listener {
	configure = proc "c" (
		data: rawptr,
		surface: ^wl.zwlr_layer_surface_v1,
		serial: c.uint32_t,
		width: c.uint32_t,
		height: c.uint32_t,
	) {
		context = runtime.default_context()
		fmt.println("layer_configure")
		canvas := cast(^Canvas)data
		wl.zwlr_layer_surface_v1_ack_configure(surface, serial)
		wl.wl_surface_damage(canvas.surface, 0, 0, c.INT32_MAX, c.INT32_MAX)
		wl.wl_surface_commit(canvas.surface)
	},
}
create_canvas :: proc(
	state: ^State,
	width: i32,
	height: i32,
	type: CanvasType,
	draw_proc: DrawProc,
) -> ^Canvas {
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

	if type == CanvasType.Window {
		xdg_surface := wl.xdg_wm_base_get_xdg_surface(state.xdg_base, canvas.surface)
		toplevel := wl.xdg_surface_get_toplevel(xdg_surface)
		wl.xdg_toplevel_set_title(toplevel, "Odin Wayland")
		wl.xdg_surface_add_listener(xdg_surface, &window_listener, canvas)
	}
	if type == CanvasType.Layer {
		layer_surface := wl.zwlr_layer_shell_v1_get_layer_surface(
			state.zwlr_layer_shell_v1,
			canvas.surface,
			nil,
			3,
			"test",
		)
		wl.zwlr_layer_surface_v1_add_listener(layer_surface, &layer_listener, canvas)
		wl.zwlr_layer_surface_v1_set_size(layer_surface, u32(width), u32(height))
		wl.zwlr_layer_surface_v1_set_anchor(
			layer_surface,
			ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM | ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT,
		)
		wl.display_dispatch(state.display) // This dispatch makes sure that the layer surface is configured
	}

	canvas.draw = draw_proc

	wl_callback := wl.wl_surface_frame(canvas.surface)
	cc := new(CanvasCallback, context.temp_allocator)
	cc.canvas = canvas
	cc.state = state
	wl.wl_callback_add_listener(wl_callback, &frame_callback, cc)
	wl.wl_surface_commit(canvas.surface)

	return canvas
}

// This should be generated once this whole thing works
wl_callback_destroy :: proc "c" (wl_callback: ^wl.wl_callback) {
	wl.proxy_destroy(cast(^wl.wl_proxy)wl_callback)
}

done :: proc "c" (data: rawptr, wl_callback: ^wl.wl_callback, callback_data: c.uint32_t) {
	context = runtime.default_context()
	cc := cast(^CanvasCallback)data
	wl_callback_destroy(wl_callback)
	callback := wl.wl_surface_frame(cc.canvas.surface)
	wl.wl_callback_add_listener(callback, &frame_callback, cc)

	cc.canvas.draw(cc.canvas, cc.state)
}

frame_callback := wl.wl_callback_listener {
	done = done,
}

set_draw_callback :: proc(state: ^State, canvas: ^Canvas, draw_proc: DrawProc) {
}
