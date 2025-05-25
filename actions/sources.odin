package actions

Action :: union {
	ApplicationAction,
	SecretAction,
	PipelineAction,
}


do_action :: proc(action: Action) {
	switch a in action {
	case ApplicationAction:
		{
			_do_action(a)
		}
	case SecretAction:
		{
			_do_action(a)
		}
	case PipelineAction:
		{
			_do_action(a)
		}
	}
}

_do_action :: proc {
	do_application_action,
	do_secret_action,
	do_pipeline_action,
}
