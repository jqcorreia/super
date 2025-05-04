package widgets

import "../engine"
import "../engine/canvas"
import "../platform"
import "core:fmt"


Label :: struct {
	x:    f32,
	y:    f32,
	text: string,
}

label_draw :: proc(label: Label, canvas: ^canvas.Canvas, state: ^engine.State) {
	canvas->draw_text(
		label.x,
		label.y,
		label.text,
		&state.font,
		state.platform_state.shaders->get("Text"),
	)
}

WidgetType :: union {
	Label,
}

draw :: proc {
	label_draw,
}
