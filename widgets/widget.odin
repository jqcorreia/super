package widgets

import "../engine"
import "../platform"
import p "../platform/primitives"
import "core:fmt"

// WidgetDrawProc :: proc(canvas: ^engine.Canvas, state: ^engine.State)

// Widget :: struct {
// 	draw: WidgetDrawProc,
// }

Label :: struct {
	x:    u32,
	y:    u32,
	text: string,
}

label_draw :: proc(label: Label, canvas: ^engine.Canvas, state: ^engine.State) {
	x := f32(label.x)
	y := f32(label.y)
	p.draw_rect(x, y, 50, 50, state.platform_state.shaders->get("Basic"), state)
	p.draw_text(label.text, u32(x), u32(y), &state.font, state.platform_state.shaders->get("Text"))
}

WidgetType :: union {
	Label,
}

draw :: proc {
	label_draw,
}
