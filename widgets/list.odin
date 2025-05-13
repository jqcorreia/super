package widgets
import "../platform"

import cv "../platform/canvas"
import "../platform/fonts"

import "../utils/gmath"
import "core:fmt"
import "core:math"
import "core:time"
import gl "vendor:OpenGL"

List :: struct {
	x:                 f32,
	y:                 f32,
	w:                 f32,
	h:                 f32,
	items:             []string,
	font:              ^fonts.Font,
	main_texture:      u32,
	scroll_offset:     f32,
	new_scroll_offset: f32,
	selected_index:    u32,
}

list_draw :: proc(list: ^List, canvas: ^cv.Canvas) {
	main_texture_w: f32 = list.w
	main_texture_h: f32 = f32(f64(len(list.items)) * list.font.line_metrics.ascender)

	if list.main_texture == 0 {
		fbo, fboTexture: u32
		gl.GenFramebuffers(1, &fbo)
		gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)

		// Create texture to render into
		gl.GenTextures(1, &fboTexture)
		gl.BindTexture(gl.TEXTURE_2D, fboTexture)
		gl.TexImage2D(
			gl.TEXTURE_2D,
			0,
			gl.RGBA,
			i32(main_texture_w),
			i32(main_texture_h),
			0,
			gl.RGBA,
			gl.UNSIGNED_BYTE,
			nil,
		)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

		gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fboTexture, 0)

		// Check status
		if (gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE) {
			fmt.println("FBO not complete!")
		}
		gl.Viewport(0, 0, i32(main_texture_w), i32(main_texture_h))

		// Draw calls
		gl.ClearColor(0.0, 0.0, 0.0, 1.0)
		// gl.ClearColor(147.0 / 255.0, 204.0 / 255., 234. / 255., 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		y: f32 = 0
		for item, idx in list.items {
			_, line_height := cv.draw_text_raw(
				{main_texture_w, main_texture_h},
				2,
				y,
				item,
				list.font,
			)
			y += line_height
		}

		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		gl.Viewport(0, 0, canvas.width, canvas.height)

		list.main_texture = fboTexture
	}

	list.scroll_offset = math.lerp(list.scroll_offset, list.new_scroll_offset, f32(0.15))

	top_v := list.scroll_offset / main_texture_h
	bottom_v := (list.scroll_offset + list.h) / main_texture_h
	vertices := []f32 {
		0.0,
		0.0,
		0.0,
		top_v,
		1.0,
		0.0,
		1.0,
		top_v,
		1.0,
		1.0,
		1.0,
		bottom_v,
		0.0,
		1.0,
		0.0,
		bottom_v,
	}
	// Draw texture in place
	canvas->draw_rect(
		list.x,
		list.y,
		list.w,
		list.h,
		vertices = &vertices,
		shader = platform.inst().shaders->get("Texture"),
		texture = list.main_texture,
	)

	// Draw scrollbar handle
	scroll_offset_max := main_texture_h - list.h
	position_percent := math.clamp(list.scroll_offset / scroll_offset_max, 0, 1)

	shh: f32 = 40.0
	shy := position_percent * (list.h - shh) + list.y
	canvas->draw_rect(list.x + list.w - 10, shy, 10, shh, color = {0.2, 0.2, 0.7, 1.0})
}

list_update :: proc(list: ^List, event: platform.InputEvent) {
	offset: f32 = 0
	#partial switch e in event {
	case platform.KeyPressed:
		{
			if e.key == platform.KeySym.XK_Down {
				offset = 100.0
			}
			if e.key == platform.KeySym.XK_Up {
				offset = -100.0
			}
		}

	}
	if offset != 0 {
		list.new_scroll_offset = math.clamp(
			list.scroll_offset + offset,
			0,
			f32(f64(len(list.items)) * list.font.line_metrics.ascender) - list.h + 10,
		)
	}
}
