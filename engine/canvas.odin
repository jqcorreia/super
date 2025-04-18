package engine

import wl "../vendor/wayland-odin/wayland"
import "core:fmt"
import "vendor:egl"

import "base:runtime"
import "core:c"

CanvasDrawProc :: proc(_: ^Canvas, _: ^State)

Canvas :: struct {
	width:       i32,
	height:      i32,
	surface:     ^wl.wl_surface,
	egl_surface: egl.Surface,
	draw:        CanvasDrawProc,
}

CanvasType :: enum {
	Layer,
	Window,
}

CanvasCallback :: struct {
	state:  ^State,
	canvas: ^Canvas,
}

window_listener := wl.xdg_surface_listener {
	configure = proc "c" (data: rawptr, surface: ^wl.xdg_surface, serial: c.uint32_t) {
		context = runtime.default_context()
		canvas := cast(^Canvas)data

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

done :: proc "c" (data: rawptr, wl_callback: ^wl.wl_callback, callback_data: c.uint32_t) {
	context = runtime.default_context()
	cc := cast(^CanvasCallback)data
	wl.wl_callback_destroy(wl_callback)
	callback := wl.wl_surface_frame(cc.canvas.surface)
	wl.wl_callback_add_listener(callback, &frame_callback, cc)

	cc.canvas.draw(cc.canvas, cc.state)
}

frame_callback := wl.wl_callback_listener {
	done = done,
}

create_canvas :: proc(
	engine_state: ^State,
	width: i32,
	height: i32,
	type: CanvasType,
	draw_proc: CanvasDrawProc,
) -> ^Canvas {
	state := engine_state.platform_state
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
			wl.ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY,
			"test",
		)
		wl.zwlr_layer_surface_v1_add_listener(layer_surface, &layer_listener, canvas)
		wl.zwlr_layer_surface_v1_set_size(layer_surface, u32(width), u32(height))
		wl.zwlr_layer_surface_v1_set_anchor(
			layer_surface,
			wl.ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM | wl.ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT,
		)
		wl.zwlr_layer_surface_v1_set_keyboard_interactivity(
			layer_surface,
			wl.ZWLR_LAYER_SURFACE_V1_KEYBOARD_INTERACTIVITY_ON_DEMAND,
		)
		wl.display_dispatch(state.display) // This dispatch makes sure that the layer surface is configured
	}

	canvas.draw = draw_proc

	wl_callback := wl.wl_surface_frame(canvas.surface)
	cc := new(CanvasCallback, context.temp_allocator)
	cc.canvas = canvas
	cc.state = engine_state
	wl.wl_callback_add_listener(wl_callback, &frame_callback, cc)
	wl.wl_surface_commit(canvas.surface)

	return canvas
}
