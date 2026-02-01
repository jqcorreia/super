package ui

import "../actions"
import "../platform"


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

draw_widget :: proc(widget: ^Widget, canvas: ^platform.Canvas) {
	switch &w in widget {
	case List(string):
		list_draw(&w, canvas)
	case List(actions.Action):
		list_draw(&w, canvas)
	case InputText:
		input_text_draw(&w, canvas)
	case Label:
		label_draw(&w, canvas)
	}
}

update_widget :: proc(widget: ^Widget, event: platform.Event) {
	switch &w in widget {
	case List(actions.Action):
		list_update(&w, event)
	case List(string):
		list_update(&w, event)
	case InputText:
		input_text_update(&w, event)
	case Label:
		label_update(&w, event)
	}
}
