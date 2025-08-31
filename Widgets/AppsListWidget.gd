extends TaskbarWidget

class_name AppsListWidget

## Bar control that contains a list of running windows in a scroll list
@export_category("Bar Properties")
@export var barColor: Color = Color.BLUE_VIOLET
# @export var bgPanel: Panel
@export var taskbarListControl: BoxContainer

var taskItems: Array[TaskbarItem]


func _ready() -> void:
	super._ready()
	
	UtilityHelper.CallOnTimer(0.2, (func() -> void:
		if(Desktop.instance and Desktop.instance.taskbarWindowItems and Desktop.instance.taskbarWindowItems.size()>0):
			for item: TaskbarItem in Desktop.instance.taskbarWindowItems:
				AddTaskItem(item)
		if(Desktop.instance):
			Desktop.instance.AddedTaskbarItem.connect(AddTaskItem)
			Desktop.instance.RemovedTaskbarItem.connect(RemoveTaskItem)
		),
		self
	)
	# if(bgPanel["theme_override_styles/panel"]):
	# 	bgPanel["theme_override_styles/panel"] = bgPanel["theme_override_styles/panel"].duplicate()

func SetBarColor(c: Color) -> void:
	barColor = c

	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING).set_parallel()

	# if(bgPanel["theme_override_styles/panel"]):
	# 	tween.tween_property(bgPanel["theme_override_styles/panel"], "bg_color", barColor, 0.5)

func HandleRightClick() -> void:
	super.HandleRightClick()
	#RClickMenuManager.instance.AddMenuItem("Change Color", ChangeColor, ResourceManager.GetResource("ColorPicker"))

#move 1 taskbar windows to a new one
func MoveWindowToNewTaskbar(bar: Taskbar) -> void:
	self.taskItems.append_array(bar.taskItems)
	var newChildren: Array[Node]
	
	#remove from old bar
	for child: Node in bar.taskbarListControl:
		newChildren.append(child)
		bar.taskbarListControl.remove_child(child)
	#add to this bar
	for child: Node in newChildren:
		add_child(child)
	

func ChangeColor() -> void:
	var dialog: DialogBox = DialogManager.instance.CreateColorDialog("Taskbar color", "OK", "Cancel", "TaskbarColor", barColor, "New bar color", Vector2(0.5,0.5))
	dialog.Closed.connect((func(d:Dictionary, bar: Taskbar) -> void:
		bar.SetBarColor(d["TaskbarColor"] as Color)
		).bind(self)
	)

func SetWidgetLayout(v: bool) -> void:
	super.SetWidgetLayout(v)
	taskbarListControl.vertical = v

func SetWidgetAnchor(anchor: E_WIDGET_ANCHOR) -> void:
	super.SetWidgetAnchor(anchor)
	if(anchor == E_WIDGET_ANCHOR.BOTTOM):
		SetWidgetLayout(false)
		#set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	elif(anchor == E_WIDGET_ANCHOR.TOP):
		SetWidgetLayout(false)
		#set_anchors_preset(Control.PRESET_TOP_WIDE)
	if(anchor == E_WIDGET_ANCHOR.LEFT):
		SetWidgetLayout(true)
		#set_anchors_preset(Control.PRESET_LEFT_WIDE)
	elif(anchor == E_WIDGET_ANCHOR.RIGHT):
		SetWidgetLayout(true)
		#set_anchors_preset(Control.PRESET_RIGHT_WIDE)

func MoveWidgetLeft() -> void:
	if(taskbarParent):
		taskbarParent.MoveWidget(self, -1)
func MoveWidgetRight() -> void:
	if(taskbarParent):
		taskbarParent.MoveWidget(self, 1)

func AddTaskItem(taskItem: TaskbarItem) -> void:
	var newItem: TaskbarItem = Desktop.instance.taskbarItemTemplate.instantiate()
	#newItem = taskItem.duplicate()
	newItem.target_window = taskItem.target_window
	if(taskItem.texture_rect.texture):
		newItem.texture_rect.texture = taskItem.texture_rect.texture#.get_node("TextureMargin/TextureRect").texture = texture
	#taskbar_button.active_color = color
	newItem.foregroundColor = taskItem.foregroundColor

	taskItems.append(newItem)
	taskbarListControl.add_child(newItem)

func RemoveTaskItem(taskItem: TaskbarItem) -> void:
	for item: TaskbarItem in taskItems:
		if(item.target_window == taskItem.target_window):
			taskItems.erase(item)
			item.queue_free()
			break
