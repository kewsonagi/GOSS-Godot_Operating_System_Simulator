extends Panel

class_name Taskbar

## Taskbar to hold pinned shortcuts to applications/widgets and other things
## Shows a list of opened windows
@export var saveFilename: String = "TaskbarConfig"
@export var saveExtension: String = ".ini"
@export_category("Taskbar Properties")
@export var bEnabled: bool = true
@export var tempUniqueID: int = 0
@export var barColor: Color = Color.BLUE_VIOLET
@export var bgPanel: Panel
@export var taskbarListControl: BoxContainer
@export var verticalBar: bool = false
var taskbarAnchor:int = Control.PRESET_BOTTOM_WIDE

#static list for all the taskbars, opened window representations, and to the save file for taskbar settings/profiles
static var barList: Array[Taskbar]
static var taskbarWindowThumbnails: Array[TaskbarItem]
var taskbarSave: SaveDataBasic = null

var widgetsList: Array[TaskbarWidget]

@export var clickHandler: HandleClick

static func AddTaskbar(bar: Taskbar) -> void:
	barList.append(bar)
static func RemoveTaskbar(bar: Taskbar) -> void:
	barList.erase(bar)

func AddWidget(widget: TaskbarWidget) -> void:
	widgetsList.append(widget)
	taskbarListControl.add_child(widget)
	widget.SetWidgetLayout(verticalBar)
	if(taskbarAnchor == Control.PRESET_LEFT_WIDE):
		widget.SetWidgetAnchor(BaseWidget.E_WIDGET_ANCHOR.LEFT)
	if(taskbarAnchor == Control.PRESET_BOTTOM_WIDE):
		widget.SetWidgetAnchor(BaseWidget.E_WIDGET_ANCHOR.BOTTOM)
	if(taskbarAnchor == Control.PRESET_TOP_WIDE):
		widget.SetWidgetAnchor(BaseWidget.E_WIDGET_ANCHOR.TOP)
	if(taskbarAnchor == Control.PRESET_RIGHT_WIDE):
		widget.SetWidgetAnchor(BaseWidget.E_WIDGET_ANCHOR.RIGHT)
	
func RemoveWidget(widget: TaskbarWidget) -> void:
	#widget.RemoveWidget()
	widgetsList.erase(widget)
	taskbarListControl.remove_child(widget)
	widget.queue_free()
	SaveBar()

func MoveWidget(widget: TaskbarWidget, moveAmount:int) -> void:
	taskbarListControl.move_child(widget, widget.get_index()-moveAmount)

func _ready() -> void:
	if(!taskbarSave):
		taskbarSave = SaveDataBasic.new()
		#no previous save file, load any defaults
		if(!taskbarSave.Load(UtilityHelper.GetCleanFileString(ResourceManager.GetPathToWindowSettings(), "%s%s" % [saveFilename, tempUniqueID], saveExtension))):#UtilityHelper.GetSavefile(ResourceManager.GetPathToWindowSettings(), saveFilename)
			#get any pre-added widgets incase we have some
			taskbarListControl.vertical = verticalBar
			for child: Node in taskbarListControl.get_children():
				if(child and child is TaskbarWidget):
					(child as TaskbarWidget).SetWidgetLayout(verticalBar)
					widgetsList.append(child as TaskbarWidget)
			
			SaveBar()
		else:
			LoadBar()

	clickHandler = get_node_or_null("ClickHandler")
	if(!clickHandler):
		clickHandler = UtilityHelper.AddInputHandler(self)
	clickHandler.RightClick.connect(HandleRightClick)

	if(bgPanel["theme_override_styles/panel"]):
		bgPanel["theme_override_styles/panel"] = bgPanel["theme_override_styles/panel"].duplicate()

func SetBarColor(c: Color, updateSave: bool = true) -> void:
	barColor = c

	# var tween: Tween = create_tween()
	# tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING).set_parallel()

	# if(bgPanel["theme_override_styles/panel"]):
	# 	tween.tween_property(bgPanel["theme_override_styles/panel"], "bg_color", barColor, 0.5)
	if(bgPanel["theme_override_styles/panel"]):
		bgPanel["theme_override_styles/panel"].bg_color = barColor
	if(updateSave):
		SaveBar()

func ToggleBar(on: bool) -> void:
	bEnabled = on
	visible = bEnabled

func SaveProfile(profileName: String) -> void:
	var profileSave: SaveDataBasic = SaveDataBasic.new()
	profileSave.Load(UtilityHelper.GetCleanFileString(ResourceManager.GetPathToWindowSettings(), "%s%s" % [saveFilename, profileName], saveExtension))
	profileSave.data = taskbarSave.data
	profileSave.Save()

func SaveBar() -> void:
	taskbarSave.data["color"] = barColor
	taskbarSave.data["numWidgets"] = widgetsList.size()
	taskbarSave.data["verticalBar"] = verticalBar
	taskbarSave.data["tempUniqueID"] = tempUniqueID
	for i: int in widgetsList.size():
		taskbarSave.data["WidgetKey:%s" % i] = widgetsList.get(i).config.key
		widgetsList.get(i).SaveWidget(taskbarSave.data)

	taskbarSave.Save()

func LoadBar() -> void:
	for widget: TaskbarWidget in widgetsList:
		#widget.RemoveWidget()
		taskbarListControl.remove_child(widget)
		widget.queue_free()
	widgetsList.clear()

	barColor = taskbarSave.Get("color", barColor)
	SetBarColor(barColor, false)
	var numWidgets:int = taskbarSave.Get("numWidgets", 0)
	verticalBar = taskbarSave.Get("verticalBar", verticalBar)
	tempUniqueID = taskbarSave.Get("tempUniqueID", tempUniqueID)
	taskbarListControl.vertical = verticalBar

	for i: int in numWidgets:
		var newWidget:TaskbarWidget = WidgetManager.CreateWidget(taskbarSave.data["WidgetKey:%s" % i])
		print(taskbarSave.data["WidgetKey:%s" % i])
		if(newWidget):
			newWidget.taskbarParent = self
			AddWidget(newWidget)

func LoadProfile(prof: String) -> void:
	var holdID: int = tempUniqueID
	var profSave: SaveDataBasic = SaveDataBasic.new()
	profSave.Load(UtilityHelper.GetCleanFileString(ResourceManager.GetPathToWindowSettings(), "%s%s" % [saveFilename, prof], saveExtension))
	LoadBar()
	tempUniqueID = holdID
	SaveBar()


func HandleRightClick() -> void:
	if(!RClickManager.instance.IsOpened()):
		RClickMenuManager.instance.ShowMenu("Taskbar", self)
	RClickMenuManager.instance.AddMenuItem("Save Profile", AskSaveProfile, ResourceManager.GetResource("Save"))
	RClickMenuManager.instance.AddMenuItem("Change Color", ChangeColor, ResourceManager.GetResource("Color"))
	RClickMenuManager.instance.AddMenuItem("Move To", MoveToMenu, ResourceManager.GetResource("Move"))
	RClickMenuManager.instance.AddMenuItem("Remove Taskbar", RemoveSelf, ResourceManager.GetResource("Delete"))

	RClickMenuManager.instance.AddMenuItem("Left", Desktop.instance.MoveTaskbarLeft.bind(self), ResourceManager.GetResource("Toggle"))
	RClickMenuManager.instance.AddMenuItem("Right", Desktop.instance.MoveTaskbarRight.bind(self), ResourceManager.GetResource("Toggle"))
	RClickMenuManager.instance.AddMenuItem("Top", Desktop.instance.MoveTaskbarTop.bind(self), ResourceManager.GetResource("Move"))
	RClickMenuManager.instance.AddMenuItem("Bottom", Desktop.instance.MoveTaskbarBottom.bind(self), ResourceManager.GetResource("Move"))

func MoveToMenu() -> void:
	RClickMenuManager.instance.ShowMenu("Taskbar Move", self)
	RClickMenuManager.instance.AddMenuItem("Left", Desktop.instance.MoveTaskbarLeft.bind(self), ResourceManager.GetResource("Toggle"))
	RClickMenuManager.instance.AddMenuItem("Right", Desktop.instance.MoveTaskbarRight.bind(self), ResourceManager.GetResource("Toggle"))
	RClickMenuManager.instance.AddMenuItem("Top", Desktop.instance.MoveTaskbarTop.bind(self), ResourceManager.GetResource("Move"))
	RClickMenuManager.instance.AddMenuItem("Bottom", Desktop.instance.MoveTaskbarBottom.bind(self), ResourceManager.GetResource("Move"))


func RemoveSelf() -> void:
	Desktop.instance.RemoveTaskbar(self)

func AnchorLeft() -> void:
	#set_anchors_preset(Control.PRESET_LEFT_WIDE)
	taskbarAnchor = Control.PRESET_LEFT_WIDE
	verticalBar = true
	taskbarListControl.vertical = true
	for widget: TaskbarWidget in widgetsList:
		widget.SetWidgetLayout(verticalBar)
		widget.SetWidgetAnchor(BaseWidget.E_WIDGET_ANCHOR.LEFT)
	SaveBar()

func AnchorRight() -> void:
	#set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	taskbarAnchor = Control.PRESET_RIGHT_WIDE
	verticalBar = true
	taskbarListControl.vertical = true
	for widget: TaskbarWidget in widgetsList:
		widget.SetWidgetLayout(verticalBar)
		widget.SetWidgetAnchor(BaseWidget.E_WIDGET_ANCHOR.RIGHT)
	SaveBar()
	
func AnchorTop() -> void:
	#set_anchors_preset(Control.PRESET_TOP_WIDE)
	taskbarAnchor = Control.PRESET_TOP_WIDE
	verticalBar = false
	taskbarListControl.vertical = false
	for widget: TaskbarWidget in widgetsList:
		widget.SetWidgetLayout(verticalBar)
		widget.SetWidgetAnchor(BaseWidget.E_WIDGET_ANCHOR.TOP)
	SaveBar()
	
func AnchorBottom() -> void:
	#set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	taskbarAnchor = Control.PRESET_BOTTOM_WIDE
	verticalBar = false
	taskbarListControl.vertical = false
	for widget: TaskbarWidget in widgetsList:
		widget.SetWidgetLayout(verticalBar)
		widget.SetWidgetAnchor(BaseWidget.E_WIDGET_ANCHOR.BOTTOM)
	
	SaveBar()
	
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

func AskSaveProfile() -> void:
	var dialog: DialogBox = DialogManager.instance.CreateInputDialog("Profile name", "OK", "Cancel", "Profile", "New Profile", "Set profile name for this taskbar", Vector2(0.5,0.5))
	dialog.Closed.connect((func(d:Dictionary, bar: Taskbar) -> void:
		bar.SaveProfile(d["Profile"])
		).bind(self)
	)

func ToggleOff() -> void:
	ToggleBar(false)

func _enter_tree() -> void:
	barList.append(self)
func _exit_tree() -> void:
	barList.erase(self)
