package ui

import pl "../platform"
import "../platform/fonts"

Label :: struct {
	x:    f32,
	y:    f32,
	text: string,
	font: ^fonts.Font,
}

label_draw :: proc(label: ^Label, canvas: ^pl.Canvas) {
	pl.draw_text(canvas, label.x, label.y, label.text, label.font)
}

label_update :: proc(input: ^Label, event: pl.Event) {
}
