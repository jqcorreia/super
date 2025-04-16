package widgets

import "../engine"
import "../platform"
import p "../platform/primitives"

WidgetDrawProc :: proc(canvas: ^engine.Canvas, state: ^engine.State)

Widget :: struct {
	x:    u32,
	y:    u32,
	draw: WidgetDrawProc,
}

Label :: struct {
	using Widget: Widget,
	text:         string,
}

label_draw :: proc(canvas: ^engine.Canvas, state: ^engine.State) {
	p.draw_rect(0, 0, 800, 600, state.platform_state.shaders->get("Basic"), state)
}

new_label :: proc(x: u32, y: u32, text: string) -> Label {
	return Label{x = 0, y = 0, draw = label_draw, text = text}
}
