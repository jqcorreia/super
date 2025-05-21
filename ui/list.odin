package ui
import "../platform"

import cv "../platform/canvas"
import "../platform/fonts"
import "../utils/xdg"

import "core:fmt"
import "core:math"
import gl "vendor:OpenGL"

import "../actions"
import "../engine"

SCROLL_SPEED :: 200
MARGIN_SIZE :: 5
ICON_SIZE :: 32

list_draw_string :: proc(
	list: List(string),
	item: string,
	x, y: f32,
	resolution: [2]f32,
) -> (
	f32,
	f32,
) {
	w, h := cv.draw_text_raw(resolution, x, y, item, list.font)

	return w, h
}


list_draw_action :: proc(
	list: List(actions.Action),
	item: actions.Action,
	x, y: f32,
	resolution: [2]f32,
) -> (
	f32,
	f32,
) {
	w, h: f32 = 0, 0
	fh := list.font.line_height
	item_size := fh + 2 * MARGIN_SIZE
	switch i in item {
	case actions.ApplicationAction:
		{
			icon := xdg.icon_manager.icon_map[xdg.IconLookup{name = i.icon, size = 32}]
			fmt.println(icon)
			img := engine.state.images->load(icon.path)
			cv.draw_image(
				resolution,
				x,
				y + (item_size - ICON_SIZE) / 2,
				img,
				w = ICON_SIZE,
				h = ICON_SIZE,
			)
			w, h = cv.draw_text(resolution, x + ICON_SIZE + 5, y + MARGIN_SIZE, i.name, list.font)
			return w, item_size
		}
	case actions.SecretAction:
		{
			w, h = cv.draw_text(resolution, x + ICON_SIZE + 5, y + MARGIN_SIZE, i.name, list.font)
			return w, item_size
		}
	}
	return 0, 0
}

list_draw_item :: proc {
	list_draw_string,
	list_draw_action,
}

List :: struct($item_type: typeid) {
	x:                 f32,
	y:                 f32,
	w:                 f32,
	h:                 f32,
	items:             []item_type,
	font:              ^fonts.Font,
	main_texture:      u32,
	main_fbo:          u32,
	scroll_offset:     f32,
	new_scroll_offset: f32,
	selected_index:    int,
	draw_item:         proc(
		list: List(item_type),
		item: item_type,
		x, y: f32,
		resolution: [2]f32,
	) -> (
		f32,
		f32,
	),
}

list_reset :: proc(list: ^$L/List) {
	list_free_fbo_and_texture(list)
	list.scroll_offset = 0
	list.new_scroll_offset = 0
	list.selected_index = 0
}

@(private)
list_free_fbo_and_texture :: proc(list: ^$L/List) {
	gl.DeleteTextures(1, &list.main_texture)
	gl.DeleteFramebuffers(1, &list.main_fbo)
	list.main_texture = 0
}

list_draw :: proc(list: ^$L/List, canvas: ^cv.Canvas) {
	item_size := list.font.line_height + 2 * MARGIN_SIZE

	main_texture_w: f32 = list.w
	main_texture_h: f32 = math.max(f32(len(list.items)) * f32(item_size), list.h)

	if list.main_texture == 0 {
		fbo, fboTexture: u32
		gl.GenFramebuffers(1, &fbo)
		gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)

		list.main_fbo = fbo

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
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

		gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fboTexture, 0)

		// Check status
		if (gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE) {
			fmt.println("FBO not complete!")
		}
		gl.Viewport(0, 0, i32(main_texture_w), i32(main_texture_h))

		// Draw calls
		gl.ClearColor(0.0, 0.0, 0.0, 0.6)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		y: f32 = 0
		for item, idx in list.items {
			if idx == list.selected_index {
				cv.draw_rect_raw(
					{main_texture_w, main_texture_h},
					0,
					y,
					100,
					list.font.line_height,
					{color = {0.0, 0.0, 1.0, 1.0}},
				)
				cv.draw_rect_raw(
					{main_texture_w, main_texture_h},
					0,
					y,
					main_texture_w,
					list.font.line_height + 2 * MARGIN_SIZE,
					{color = {0.2, 0.2, 0.4, 1.0}},
				)
			}
			draw_func := list.draw_item != nil ? list.draw_item : list_draw_item
			_, line_height := draw_func(list^, item, 2, y, {main_texture_w, main_texture_h})
			y += line_height
		}

		// Unbind framebuffer and reset viewport
		gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
		gl.Viewport(0, 0, canvas.width, canvas.height)
		gl.BindTexture(gl.TEXTURE_2D, 0)

		gl.Flush()

		list.main_texture = fboTexture
	}

	list.scroll_offset = math.lerp(list.scroll_offset, list.new_scroll_offset, f32(0.15))

	top_v := math.clamp(list.scroll_offset / main_texture_h, 0, 1)
	bottom_v := math.clamp((list.scroll_offset + list.h) / main_texture_h, 0, 1)
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
	cv.draw_rect(
		canvas,
		list.x,
		list.y,
		list.w,
		math.min(list.h, main_texture_h),
		{vertices = &vertices, texture = list.main_texture, flip_texture_y = true, tag = "list"},
	)

	// Draw scrollbar handle
	scroll_offset_max := main_texture_h - list.h
	position_percent := math.clamp(list.scroll_offset / scroll_offset_max, 0, 1)

	shh: f32 = 40.0
	shw: f32 = 5.0
	shy := position_percent * (list.h - shh) + list.y
	cv.draw_rect(canvas, list.x + list.w - shw, shy, shw, shh, {color = {0.2, 0.2, 0.7, 1.0}})
}

list_update :: proc(list: ^$L/List, event: platform.InputEvent) {
	offset: f32 = 0
	#partial switch e in event {
	case platform.KeyPressed:
		{
			if e.key == platform.KeySym.XK_Page_Down {
				offset = SCROLL_SPEED
			}
			if e.key == platform.KeySym.XK_Page_Up {
				offset = -SCROLL_SPEED
			}
			if e.key == platform.KeySym.XK_Down {
				list.selected_index += 1
				list.main_texture = 0
			}
			if e.key == platform.KeySym.XK_Up {
				list.selected_index -= 1
				list_free_fbo_and_texture(list)
			}
		}
	}
	if offset != 0 {
		item_size := list.font.line_height + 2 * MARGIN_SIZE
		rendered_height := f32(len(list.items)) * f32(item_size)

		if rendered_height < list.h {
			// Do not scroll
			list.new_scroll_offset = 0
			return
		}
		// This is the number of lines minus line height - the height of the list 'container'
		// The abs here is to account for the actual list be smaller than the container
		max_scroll_offset := math.abs(rendered_height - list.h)
		list.new_scroll_offset = math.clamp(list.scroll_offset + offset, 0, max_scroll_offset)
	}
}
