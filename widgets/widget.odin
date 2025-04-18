package widgets

import "../engine"
import "../platform"
import p "../platform/primitives"
import "core:fmt"


Label :: struct {
	x:    f32,
	y:    f32,
	text: string,
}

label_draw :: proc(label: Label, canvas: ^engine.Canvas, state: ^engine.State) {
	p.draw_text(
		label.text,
		label.x,
		label.y,
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
