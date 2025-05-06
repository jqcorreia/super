package widgets

import "../engine"
import "../platform"
import "../platform/canvas"
import "core:fmt"


Label :: struct {
	x:    f32,
	y:    f32,
	text: string,
	font: ^platform.Font,
}

label_draw :: proc(label: Label, canvas: ^canvas.Canvas) {
	canvas->draw_text(
		label.x,
		label.y,
		label.text,
		label.font,
		engine.platform.shaders->get("Text"),
	)
}

WidgetType :: union {
	Label,
}

draw :: proc {
	label_draw,
}
