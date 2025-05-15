package canvas

import pl "../../platform"
import "../../platform/fonts"
import "../../types"
import "../../utils/gmath"
import "../../vendor/libschrift-odin/sft"
import wl "../../vendor/wayland-odin/wayland"

import "base:runtime"
import "core:c"
import "core:fmt"
import "vendor:egl"


CanvasDrawProc :: proc(_: ^Canvas)

Canvas :: struct {
	width:         i32,
	height:        i32,
	surface:       ^wl.wl_surface,
	layer_surface: ^wl.zwlr_layer_surface_v1,
	egl_surface:   egl.Surface,
	draw_proc:     CanvasDrawProc,
	draw_rect:     proc(
		canvas: ^Canvas,
		x, y, width, height: f32,
		vertices: ^[]f32 = nil,
		color: types.Color = types.Color{0.0, 0.0, 0.0, 0.0},
		shader: u32 = 0,
		texture: u32 = 0,
	),
	draw_text:     proc(
		canvas: ^Canvas,
		x, y: f32,
		text: string,
		font: ^fonts.Font,
		shader: u32 = 0,
	) -> (
		f32,
		f32,
	),
}

CanvasType :: enum {
	Layer,
	Window,
	Modal,
}

CanvasCallback :: struct {
	platform_state: ^pl.PlatformState,
	canvas:         ^Canvas,
}


ortho :: gmath.ortho

recreate_egl_window :: proc(
	canvas: ^Canvas,
	egl_render_context: pl.RenderContext,
	width: i32,
	height: i32,
) {
	fmt.println("Recreate EGL window")
	egl_window := wl.egl_window_create(canvas.surface, width, height)
	egl_surface := egl.CreateWindowSurface(
		egl_render_context.display,
		egl_render_context.config,
		egl.NativeWindowType(egl_window),
		nil,
	)

	if egl_surface == egl.NO_SURFACE {
		fmt.println("Error creating window surface")
	}
	if (!egl.MakeCurrent(
			   egl_render_context.display,
			   egl_surface,
			   egl_surface,
			   egl_render_context.ctx,
		   )) {
		fmt.println("Error making current!")
	}

	canvas.egl_surface = egl_surface
}
window_listener := wl.xdg_surface_listener {
	configure = proc "c" (data: rawptr, surface: ^wl.xdg_surface, serial: c.uint32_t) {
		context = runtime.default_context()
		fmt.println("window configure")
		cc := cast(^CanvasCallback)data
		canvas := cc.canvas
		state := cc.platform_state

		wl.xdg_surface_ack_configure(surface, serial)
		wl.wl_surface_damage(canvas.surface, 0, 0, c.INT32_MAX, c.INT32_MAX)
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
		fmt.println("Top level configure")
		cc := cast(^CanvasCallback)data
		canvas := cc.canvas
		egl_render_context := cc.platform_state.egl_render_context
		fmt.println(canvas.width, width, canvas.height, height)
		if canvas.width != width || canvas.height != height {
			recreate_egl_window(canvas, egl_render_context, i32(width), i32(height))
			canvas.width = width
			canvas.height = height
		}

	},
	close = proc "c" (data: rawptr, xdg_toplevel: ^wl.xdg_toplevel) {},
	configure_bounds = proc "c" (
		data: rawptr,
		xdg_toplevel: ^wl.xdg_toplevel,
		width: c.int32_t,
		height: c.int32_t,
	) {},
	wm_capabilities = proc "c" (
		data: rawptr,
		xdg_toplevel: ^wl.xdg_toplevel,
		capabilities: ^wl.wl_array,
	) {},
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
		cc := cast(^CanvasCallback)data
		canvas := cc.canvas
		state := cc.platform_state

		// recreate_egl_window(canvas, state.egl_render_context, i32(width), i32(height))
		canvas.width = i32(width)
		canvas.height = i32(height)

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

	cc.canvas.draw_proc(cc.canvas)
}

frame_callback := wl.wl_callback_listener {
	done = done,
}

create_canvas :: proc(
	platform: ^pl.PlatformState,
	width: i32,
	height: i32,
	type: CanvasType,
	draw_proc: CanvasDrawProc,
) -> ^Canvas {
	canvas := new(Canvas)
	canvas.width = width
	canvas.height = height
	canvas.surface = wl.wl_compositor_create_surface(platform.compositor)

	canvas.draw_rect = draw_rect
	canvas.draw_text = draw_text
	if canvas.surface == nil {
		fmt.println("Error creating surface")
		return canvas
	}


	cc := new(CanvasCallback, context.temp_allocator)
	cc.canvas = canvas
	cc.platform_state = platform

	egl_window := wl.egl_window_create(canvas.surface, i32(width), i32(height))
	egl_surface := egl.CreateWindowSurface(
		platform.egl_render_context.display,
		platform.egl_render_context.config,
		egl.NativeWindowType(egl_window),
		nil,
	)

	if egl_surface == egl.NO_SURFACE {
		fmt.println("Error creating window surface")

	}
	if (!egl.MakeCurrent(
			   platform.egl_render_context.display,
			   egl_surface,
			   egl_surface,
			   platform.egl_render_context.ctx,
		   )) {
		fmt.println("Error making current!")
	}

	if (!platform.default_shaders_loaded) {
		pl.create_default_shaders()
		platform.default_shaders_loaded = true
	}

	canvas.egl_surface = egl_surface
	if type == CanvasType.Window {
		xdg_surface := wl.xdg_wm_base_get_xdg_surface(platform.xdg_base, canvas.surface)
		toplevel := wl.xdg_surface_get_toplevel(xdg_surface)
		wl.xdg_toplevel_add_listener(toplevel, &toplevel_listener, cc)
		wl.xdg_toplevel_set_title(toplevel, "Odin Wayland")
		wl.xdg_surface_add_listener(xdg_surface, &window_listener, cc)
	}
	if type == CanvasType.Layer {
		layer_surface := wl.zwlr_layer_shell_v1_get_layer_surface(
			platform.zwlr_layer_shell_v1,
			canvas.surface,
			nil,
			wl.ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY,
			"test",
		)
		// Store it in canvas for resizing
		canvas.layer_surface = layer_surface
		wl.zwlr_layer_surface_v1_add_listener(layer_surface, &layer_listener, cc)
		wl.zwlr_layer_surface_v1_set_size(layer_surface, u32(width), u32(height))
		wl.zwlr_layer_surface_v1_set_anchor(
			layer_surface,
			0,
			// wl.ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM | wl.ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT,
		)
		wl.zwlr_layer_surface_v1_set_keyboard_interactivity(
			layer_surface,
			wl.ZWLR_LAYER_SURFACE_V1_KEYBOARD_INTERACTIVITY_ON_DEMAND,
		)
		wl.display_dispatch(platform.display) // This dispatch makes sure that the layer surface is configured
	}

	canvas.draw_proc = draw_proc

	wl_callback := wl.wl_surface_frame(canvas.surface)
	wl.wl_callback_add_listener(wl_callback, &frame_callback, cc)
	wl.wl_surface_commit(canvas.surface)

	return canvas
}
