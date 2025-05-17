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
	egl_window:    ^wl.egl_window,
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
	ready:         bool,
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

resize_egl_window :: proc(
	canvas: ^Canvas,
	egl_render_context: pl.RenderContext,
	width: i32,
	height: i32,
) {
	fmt.println("Resize EGL window")
	wl.egl_window_resize(canvas.egl_window, c.int(width), c.int(height), 0, 0)
}
create_egl_window :: proc(
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
	canvas.egl_window = egl_window
}

done :: proc "c" (data: rawptr, wl_callback: ^wl.wl_callback, callback_data: c.uint32_t) {
	context = runtime.default_context()
	cc := cast(^CanvasCallback)data

	wl.wl_callback_destroy(wl_callback)
	callback := wl.wl_surface_frame(cc.canvas.surface)
	wl.wl_callback_add_listener(callback, &frame_callback, cc)

	if cc.canvas.ready {
		cc.canvas.draw_proc(cc.canvas)
	}
}

frame_callback := wl.wl_callback_listener {
	done = done,
}

create_canvas :: proc(
	platform: ^pl.PlatformState,
	width: u32,
	height: u32,
	type: CanvasType,
	draw_proc: CanvasDrawProc,
) -> ^Canvas {
	canvas := new(Canvas)
	canvas.width = i32(width)
	canvas.height = i32(height)
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

	fmt.println("Create canvas")
	if type == CanvasType.Window {
		init_window_canvas(cc)
	}
	if type == CanvasType.Layer {
		init_layer_canvas(cc, width, height)
	}

	canvas.draw_proc = draw_proc

	wl_callback := wl.wl_surface_frame(canvas.surface)
	wl.wl_callback_add_listener(wl_callback, &frame_callback, cc)
	wl.wl_surface_commit(canvas.surface)

	// Why should I need 2 of these in order to trigger the listeners and all that?
	// This makes me use display_dispatch_pending in the render loop in order not to block
	wl.display_dispatch(platform.display)
	wl.display_dispatch(platform.display)

	return canvas
}
