package widgets

import "../platform"
import "../platform/canvas"

Label :: struct {
	x:    f32,
	y:    f32,
	text: string,
	font: ^platform.Font,
}

label_draw :: proc(label: Label, canvas: ^canvas.Canvas) {
	canvas->draw_text(label.x, label.y, label.text, label.font)
}

