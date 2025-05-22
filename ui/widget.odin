package ui

import "../actions"


Widget :: union {
	Label,
	List(string),
	List(actions.Action),
	InputText,
}

WidgetBase :: struct {
	x: f32,
	y: f32,
	w: f32,
	h: f32,
}

draw :: proc {
	label_draw,
	list_draw,
	input_text_draw,
}

update :: proc {
	list_update,
	input_text_update,
}

draw_widget :: proc(widget: $S/Widget) {
	w := widget.(S)
	draw(w)
}

// import cv "../platform/canvas"

// Widget2 :: struct {
// 	type: Widget_Type,
// }

// Widget_Type :: enum {
// 	Widget,
// 	Button,
// }

// Button :: struct {
// 	using base: Widget2,
// }

// Widget_Draw :: #type proc(w: ^Widget2, c: ^cv.Canvas)

// button_draw :: proc(w: ^Widget2, c: ^cv.Canvas) {

// 	b := cast(^Button)w
// }

// @(rodata)
// DRAWS := map[Widget_Type]Widget_Draw {
// 	.Button = button_draw,
// }

// widget_draw :: proc(w: ^Widget2, c: ^cv.Canvas) {
// 	if draw, ok := DRAWS[w.type]; ok do draw(w, c)
// }
