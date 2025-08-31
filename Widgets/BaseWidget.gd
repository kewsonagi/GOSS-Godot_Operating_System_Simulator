extends Control

class_name BaseWidget

enum E_WIDGET_ANCHOR {LEFT, RIGHT, TOP, BOTTOM, FULL}

@export_category("Widget properties")
@export var config: WidgetConfig
@export var anchorPreset: E_WIDGET_ANCHOR = E_WIDGET_ANCHOR.FULL
@export var verticalWidget: bool
var clickHandler: HandleClick

func _ready() -> void:
	clickHandler = get_node_or_null("ClickHandler")
	if(!clickHandler):
		clickHandler = UtilityHelper.AddInputHandler(self)
	clickHandler.RightClick.connect(HandleRightClick)

func HandleRightClick() -> void:
	RClickMenuManager.instance.ShowMenu("Window list widget", self)
	RClickMenuManager.instance.AddMenuItem("Remove", RemoveWidget, ResourceManager.GetResource("Delete"))
	
func SetConfig(c: WidgetConfig) -> void:
	config = c

func RemoveWidget() -> void:
	return

#dataset to put save info in, usually provided by the parent taskbar or desktop
func SaveWidget(data: Dictionary) -> void:
	return

func LoadWidget(data: Dictionary) -> void:
	return

func SetWidgetLayout(v: bool) -> void:
	verticalWidget = v

func SetWidgetAnchor(anchor: E_WIDGET_ANCHOR) -> void:
	anchorPreset = anchor