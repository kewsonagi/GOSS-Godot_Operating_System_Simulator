extends BaseWidget

class_name TaskbarWidget

@export_category("taskbar properties")
@export var taskbarParent: Taskbar
@export var transformControl: Control

func RemoveWidget() -> void:
	super.RemoveWidget()
	if(taskbarParent):
		taskbarParent.RemoveWidget(self)

#dataset to put save info in, usually provided by the parent taskbar or desktop
func SaveWidget(data: Dictionary) -> void:
	super.SaveWidget(data)

func LoadWidget(data: Dictionary) -> void:
	super.LoadWidget(data)

func SetWidgetLayout(v: bool) -> void:
	super.SetWidgetLayout(v)

func SetWidgetAnchor(anchor: E_WIDGET_ANCHOR) -> void:
	super.SetWidgetAnchor(anchor)
