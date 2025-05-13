package widgets

import "../platform"
import "../platform/canvas"
import "../platform/fonts"

import "core:fmt"
import "core:math"
import "core:strings"

InputText :: struct {
	x:        f32,
	y:        f32,
	w:        f32,
	h:        f32,
	text:     string,
	font:     fonts.Font,
	cursor_x: f32,
}

input_text_draw :: proc(input: ^InputText, cv: ^canvas.Canvas) {
	tw, th := cv->draw_text(input.x, input.y, input.text, &input.font)
	input.cursor_x = math.lerp(input.cursor_x, input.x + tw, f32(0.5))
	cv->draw_rect(input.x + input.cursor_x, input.y, 10, th, color = {0.1, 0.2, 0.7, 1.0})
}

input_text_update :: proc(input: ^InputText, event: platform.InputEvent) {
	#partial switch e in event {
	case platform.KeyPressed:
		{
			if e.key == platform.KeySym.XK_BackSpace {
				if len(input.text) > 0 {
					input.text, _ = strings.substring(
						input.text,
						0,
						strings.rune_count(input.text) - 1,
					)
				}
			}
			fmt.println("Key pressed: ", e.key)
		}
	case platform.TextInput:
		{
			input.text = strings.concatenate([]string{input.text, e.text})
		}
	}
}
