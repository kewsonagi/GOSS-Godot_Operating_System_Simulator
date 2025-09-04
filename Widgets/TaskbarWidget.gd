extends BaseWidget

class_name TaskbarWidget

@export_category("taskbar properties")
@export var taskbarParent: Taskbar
@export var transformControl: Control

func RemoveWidget() -> void:
	super.RemoveWidget()
	if(taskbarParent):
		taskbarParent.RemoveWidget(self)

func HandleRightClick() -> void:
	super.HandleRightClick()
	RClickMenuManager.instance.AddMenuItem("Move %s" % config.key, func() -> void: UtilityHelper.CallOnTimer(0.05, MoveWidget, self), ResourceManager.GetResource("Move"))

func MoveWidget() -> void:
	RClickMenuManager.instance.ShowMenu("Move Widget", self)
	#dont show moving left or to the start if we are already in that spot
	if(self.get_index()>0):
		RClickMenuManager.instance.AddMenuItem("End", taskbarParent.MoveWidget.bind(self, -self.get_index()), ResourceManager.GetResource("Move"), Color.TURQUOISE)
		RClickMenuManager.instance.AddMenuItem("Right", taskbarParent.MoveWidget.bind(self, -1), ResourceManager.GetResource("Move"), Color.YELLOW_GREEN)
	#dont show shifting right or move to the end if we are currently the last widget added
	if(self.get_index()<get_parent().get_child_count()-1):
		RClickMenuManager.instance.AddMenuItem("Left", taskbarParent.MoveWidget.bind(self, 1), ResourceManager.GetResource("Move"), Color.GREEN_YELLOW)
		RClickMenuManager.instance.AddMenuItem("Start", taskbarParent.MoveWidget.bind(self, get_parent().get_child_count()-self.get_index()-1), ResourceManager.GetResource("Move"), Color.MISTY_ROSE)
	
#dataset to put save info in, usually provided by the parent taskbar or desktop
func SaveWidget(data: Dictionary) -> void:
	super.SaveWidget(data)

func LoadWidget(data: Dictionary) -> void:
	super.LoadWidget(data)

func SetWidgetLayout(v: bool) -> void:
	super.SetWidgetLayout(v)

func SetWidgetAnchor(anchor: E_WIDGET_ANCHOR) -> void:
	super.SetWidgetAnchor(anchor)
