package widgets

import "../actions"


WidgetType :: enum {
	Label,
	List,
	InputText,
}

Widget :: union {
	Label,
	List(string),
	List(actions.Action),
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
