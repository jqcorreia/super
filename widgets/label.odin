package widgets

import "../platform/canvas"
import "../platform/fonts"

Label :: struct {
	x:    f32,
	y:    f32,
	text: string,
	font: ^fonts.Font,
}

label_draw :: proc(label: Label, canvas: ^canvas.Canvas) {
	canvas->draw_text(label.x, label.y, label.text, label.font)
}
