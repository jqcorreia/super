package widgets

import "../engine"
import "../platform"
import "../platform/canvas"
import "core:fmt"


WidgetType :: enum {
	Label,
	List,
	InputText,
}

Widget :: union {
	Label,
	List(string),
	InputText,
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
