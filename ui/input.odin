package ui

import pl "../platform"
import "../platform/fonts"

import "core:math"
import "core:strings"

import gl "vendor:OpenGL"

InputText :: struct {
	using base: WidgetBase,
	text:       string,
	font:       fonts.Font,
	cursor_x:   f32,
}

input_text_draw :: proc(input: ^InputText, canvas: ^pl.Canvas) {
	pl.draw_rect(
		canvas,
		input.x,
		input.y,
		input.w,
		input.h,
		{color = current_theme.input_border_color, shader = pl.get_shader("Rounded")},
	)
	rect: []i32 = {
		i32(input.x),
		i32(f32(canvas.height) - input.y - input.h),
		i32(input.w),
		i32(input.h),
	}
	gl.Enable(gl.SCISSOR_TEST)
	gl.Scissor(rect[0], rect[1], rect[2], rect[3])
	x := input.x + 5
	text_y := input.y + ((input.h - input.font.line_height) / 2)

	tw, th := pl.draw_text(
		canvas,
		x,
		text_y,
		input.text,
		&input.font,
		color = current_theme.input_text_color,
	)

	// Draw cursor
	input.cursor_x = math.lerp(input.cursor_x, tw, f32(0.35))

	// Draw the cursor at the text_y in the cursor x position with a fifth of the text height
	pl.draw_rect(canvas, x + input.cursor_x, text_y, th / 5, th, {color = {0.1, 0.2, 0.7, 1.0}})

	gl.Scissor(0, 0, canvas.width, canvas.height)
	gl.Disable(gl.SCISSOR_TEST)
}

input_text_update :: proc(input: ^InputText, event: pl.Event) {
	#partial switch e in event {
	case pl.KeyPressed:
		{
			if e.key == pl.KeySym.XK_BackSpace {
				if len(input.text) > 0 {
					input.text, _ = strings.substring(
						input.text,
						0,
						strings.rune_count(input.text) - 1,
					)
				}
			}
		}
	case pl.TextInput:
		{
			input.text = strings.concatenate([]string{input.text, e.text})
		}
	}
}
