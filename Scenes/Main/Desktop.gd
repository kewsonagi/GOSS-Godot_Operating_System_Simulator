extends Control

class_name Desktop

@export var taskbarTemplate: PackedScene = preload("res://Widgets/taskbar.tscn")
@export var taskbarItemTemplate: PackedScene
@export var gameWindowTemplate: PackedScene
## The desktop file manager.
@export var filemanager: DesktopFileManager
@export var anchorContainerLeft: BoxContainer
@export var anchorContainerRight: BoxContainer
@export var anchorContainerBottom: BoxContainer
@export var anchorContainerTop: BoxContainer
@export var taskbars: Array[Taskbar]
@export var widgets: Array[BaseWidget]
static var taskbarWindowItems: Array[TaskbarItem]
static var windows: Array[FakeWindow] = []
static var desktopRect: Rect2
static var desktopFullscreen: Rect2
var clickHandler: HandleClick
static var instance: Desktop
static var desktopSave: SaveDataBasic
static var uniqueIDCounter: int = 0


signal AddedWindow(window: FakeWindow)
signal ClosedWindow(window: FakeWindow)
signal AddedTaskbarItem(taskItem: TaskbarItem)
signal RemovedTaskbarItem(taskItem: TaskbarItem)
signal ResizedDesktop(newSize: Rect2)
signal AddedWidget(widget: BaseWidget)
signal RemovedWidget(widget: BaseWidget)

func _ready() -> void:
	if(!instance):
		instance = self

	get_parent().move_child.call_deferred(self, 0)
	clickHandler = UtilityHelper.AddInputHandler(self)
	#filemanager.RightClickEnd.connect(HandleRightClick)
	if(filemanager):
		filemanager.RightClickMenuOpened.connect(HandleRightClick)
	else:
		clickHandler.RightClick.connect(HandleRightClick)

	for taskbar: Control in anchorContainerLeft.get_children():
		taskbars.append(taskbar)
	for taskbar: Control in anchorContainerRight.get_children():
		taskbars.append(taskbar)
	for taskbar: Control in anchorContainerBottom.get_children():
		taskbars.append(taskbar)
	for taskbar: Control in anchorContainerTop.get_children():
		taskbars.append(taskbar)

	desktopFullscreen = Rect2(0,0,size.x,size.y)
	desktopRect = Rect2(anchorContainerLeft.size.x ,anchorContainerTop.size.y, size.x - anchorContainerRight.size.x, size.y - anchorContainerBottom.size.y)
	#UpdateTaskbars()
	
	#loaded a previous save file
	if(!desktopSave):
		desktopSave = SaveDataBasic.new()
		if(desktopSave.Load(UtilityHelper.GetCleanFileString(ResourceManager.GetPathToWindowSettings(), "DesktopSettings", ".tres"))):
			LoadDesktop()
		else:
			for child: Taskbar in anchorContainerBottom.get_children():
				child.tempUniqueID = uniqueIDCounter
				uniqueIDCounter+=1
				child.SaveBar()
			for child: Taskbar in anchorContainerTop.get_children():
				child.tempUniqueID = uniqueIDCounter
				uniqueIDCounter+=1
				child.SaveBar()
			for child: Taskbar in anchorContainerLeft.get_children():
				child.tempUniqueID = uniqueIDCounter
				uniqueIDCounter+=1
				child.SaveBar()
			for child: Taskbar in anchorContainerRight.get_children():
				child.tempUniqueID = uniqueIDCounter
				uniqueIDCounter+=1
				child.SaveBar()
		SaveDesktop()
	
	UtilityHelper.CallOnTimer(0.5, UpdateTaskbars, self)

func _OnResized() -> void:
	desktopFullscreen = Rect2(0,0,size.x,size.y)
	UpdateTaskbars()
	ResizedDesktop.emit(desktopRect)

func HandleRightClick() -> void:
	if(!RClickManager.instance.IsOpened()):
		RClickMenuManager.instance.ShowMenu("Desktop Menu", self, Color.YELLOW)
	RClickMenuManager.instance.AddMenuItem("Add Taskbar", AddTaskbar, ResourceManager.GetResource("Add"))

func AddTaskbar() -> void:
	var newTaskbar: Taskbar = taskbarTemplate.instantiate()
	if(newTaskbar):
		uniqueIDCounter+=1
		newTaskbar.tempUniqueID = uniqueIDCounter
		anchorContainerBottom.add_child(newTaskbar)
		taskbars.append(newTaskbar)
		newTaskbar.AnchorBottom()
	
	UtilityHelper.CallOnTimer(0.5, UpdateTaskbars, self)
	AddedWidget.emit(newTaskbar)

func RemoveTaskbar(taskbar: Taskbar) -> void:
	taskbars.erase(taskbar)

	taskbar.queue_free()
	UtilityHelper.CallOnTimer(0.5, UpdateTaskbars, self)
	RemovedWidget.emit(taskbar)

func UpdateTaskbars() -> void:
	desktopRect = Rect2(anchorContainerLeft.size.x ,anchorContainerTop.size.y, size.x - anchorContainerRight.size.x, size.y - anchorContainerBottom.size.y)

	anchorContainerLeft.anchor_top = anchorContainerTop.size.y / desktopFullscreen.size.y
	anchorContainerRight.anchor_top = anchorContainerTop.size.y / desktopFullscreen.size.y
	filemanager.anchor_top = anchorContainerTop.size.y / desktopFullscreen.size.y

	anchorContainerLeft.anchor_bottom = 1 - (anchorContainerBottom.size.y / desktopFullscreen.size.y)
	anchorContainerRight.anchor_bottom = 1 - (anchorContainerBottom.size.y / desktopFullscreen.size.y)
	filemanager.anchor_bottom = 1 - (anchorContainerBottom.size.y / desktopFullscreen.size.y)

	filemanager.anchor_left = anchorContainerLeft.size.x / desktopFullscreen.size.x
	filemanager.anchor_right = 1 - (anchorContainerRight.size.x / desktopFullscreen.size.x)

	SaveDesktop()

func SpawnWindow(sceneToLoadInsideWindow: String, windowName: String = "Untitled", windowID: String ="game", data: Dictionary = {}, parentWindow: Node = null) -> Node:
	var window: FakeWindow
	window = ResourceLoader.load(sceneToLoadInsideWindow).instantiate()
	
	window.title_text = windowName;
	window.SetID(windowID)
	window.SetData(data)
	if(parentWindow):
		parentWindow.add_child(window)
	else:
		get_tree().current_scene.add_child(window)
	window.move_to_front()
	
	windows.append(window)
	window.deleted.connect(CloseWindow)

	AddedWindow.emit(window)
		
	return window as Node

func SpawnGameWindow(sceneToLoadInsideWindow: String, windowName: String = "Untitled", windowID: String ="game", data: Dictionary = {}, parentWindow: Node = null) -> Node:
	#var boot: BootGame = load("res://Scenes/Window/Game Window/game_window.tscn").instantiate()
	var window: FakeWindow
	window = gameWindowTemplate.instantiate()#ResourceLoader.load("res://Scenes/Window/Game Window/game_window.tscn").instantiate()
	data["BootScene"] = sceneToLoadInsideWindow

	window.title_text = windowName;
	window.SetID(windowID)
	window.SetData(data)
	if(parentWindow):
		parentWindow.add_child(window)
	else:
		get_tree().current_scene.add_child(window)
	window.move_to_front()
	
	windows.append(window)
	window.deleted.connect(CloseWindow)

	AddedWindow.emit(window)

	return window as Node

func AddWindowToTaskbar(window: FakeWindow, color: Color = Color.LIGHT_YELLOW, texture: Texture2D=null) -> void:
	#add window to taskbar
	var taskbarItem: TaskbarItem = taskbarItemTemplate.instantiate()#ResourceLoader.load("res://Scenes/Taskbar/TaskbarItem.tscn").instantiate()
	taskbarItem.target_window = window
	if(texture):
		taskbarItem.texture_rect.texture = texture#.get_node("TextureMargin/TextureRect").texture = texture
	#taskbar_button.active_color = color
	taskbarItem.foregroundColor = color

	taskbarWindowItems.append(taskbarItem)

	AddedTaskbarItem.emit(taskbarItem)
	#get_tree().get_first_node_in_group("taskbar_buttons").add_child(taskbar_button)

func RemoveTaskbarWindowItem(taskItem: TaskbarItem) -> void:
	taskbarWindowItems.erase(taskItem)
	RemovedTaskbarItem.emit(taskItem)

func CloseWindow(window: FakeWindow) -> void:
	for item: TaskbarItem in taskbarWindowItems:
		if(item.target_window == window):
			RemoveTaskbarWindowItem(item)
			break
	windows.erase(window)
	ClosedWindow.emit(window)
	
func _exit_tree() -> void:
	windows.clear()

func MoveTaskbarLeft(taskbar: Taskbar) -> void:
	taskbar.get_parent().remove_child(taskbar)
	anchorContainerLeft.add_child(taskbar)
	taskbar.AnchorLeft()
	SaveDesktop()

func MoveTaskbarRight(taskbar: Taskbar) -> void:
	taskbar.get_parent().remove_child(taskbar)
	anchorContainerRight.add_child(taskbar)
	taskbar.AnchorRight()
	SaveDesktop()

func MoveTaskbarTop(taskbar: Taskbar) -> void:
	taskbar.get_parent().remove_child(taskbar)
	anchorContainerTop.add_child(taskbar)
	taskbar.AnchorTop()
	SaveDesktop()

func MoveTaskbarBottom(taskbar: Taskbar) -> void:
	taskbar.get_parent().remove_child(taskbar)
	anchorContainerBottom.add_child(taskbar)
	taskbar.AnchorBottom()
	SaveDesktop()

func SaveDesktop() -> void:
	desktopSave.data["uniqueIDCounter"] = uniqueIDCounter
	desktopSave.data["anchorContainerBottom:children"] = anchorContainerBottom.get_child_count()
	desktopSave.data["anchorContainerTop:children"] = anchorContainerTop.get_child_count()
	desktopSave.data["anchorContainerLeft:children"] = anchorContainerLeft.get_child_count()
	desktopSave.data["anchorContainerRight:children"] = anchorContainerRight.get_child_count()
	for i: int in anchorContainerBottom.get_child_count():
		desktopSave.data["anchorContainerBottom:%s" % [i]] = anchorContainerBottom.get_child(i).tempUniqueID
	for i: int in anchorContainerTop.get_child_count():
		desktopSave.data["anchorContainerTop:%s" % [i]] = anchorContainerTop.get_child(i).tempUniqueID
	for i: int in anchorContainerLeft.get_child_count():
		desktopSave.data["anchorContainerLeft:%s" % [i]] = anchorContainerLeft.get_child(i).tempUniqueID
	for i: int in anchorContainerRight.get_child_count():
		desktopSave.data["anchorContainerRight:%s" % [i]] = anchorContainerRight.get_child(i).tempUniqueID

	desktopSave.Save()

func LoadDesktop() -> void:
	print(desktopSave.data)
	uniqueIDCounter = desktopSave.Get("uniqueIDCounter", uniqueIDCounter)
	for child: Node in anchorContainerBottom.get_children():
		child.queue_free()
	for child: Node in anchorContainerTop.get_children():
		child.queue_free()
	for child: Node in anchorContainerLeft.get_children():
		child.queue_free()
	for child: Node in anchorContainerRight.get_children():
		child.queue_free()
	
	
	var containerCount: int = desktopSave.Get("anchorContainerBottom:children", 0)
	var newTaskbar: Taskbar
	print("anchorContainerBottom: %s" % containerCount)
	for i: int in containerCount:
		newTaskbar = taskbarTemplate.instantiate()
		newTaskbar.tempUniqueID = desktopSave.Get("anchorContainerBottom:%s" % [i], newTaskbar.tempUniqueID)
		taskbars.append(newTaskbar)
		anchorContainerBottom.add_child(newTaskbar)
		newTaskbar.LoadBar()
		newTaskbar.AnchorBottom()

	containerCount = desktopSave.Get("anchorContainerTop:children", 0)
	print("anchorContainerTop: %s" % containerCount)
	for i: int in containerCount:
		newTaskbar = taskbarTemplate.instantiate()
		newTaskbar.tempUniqueID = desktopSave.Get("anchorContainerTop:%s" % [i], newTaskbar.tempUniqueID)
		taskbars.append(newTaskbar)
		anchorContainerTop.add_child(newTaskbar)
		newTaskbar.LoadBar()
		newTaskbar.AnchorTop()

	containerCount = desktopSave.Get("anchorContainerLeft:children", 0)
	print("anchorContainerLeft: %s" % containerCount)
	for i: int in containerCount:
		newTaskbar = taskbarTemplate.instantiate()
		newTaskbar.tempUniqueID = desktopSave.Get("anchorContainerLeft:%s" % [i], newTaskbar.tempUniqueID)
		taskbars.append(newTaskbar)
		anchorContainerLeft.add_child(newTaskbar)
		newTaskbar.LoadBar()
		newTaskbar.AnchorLeft()

	containerCount = desktopSave.Get("anchorContainerRight:children", 0)
	print("anchorContainerRight: %s" % containerCount)
	for i: int in containerCount:
		newTaskbar = taskbarTemplate.instantiate()
		newTaskbar.tempUniqueID = desktopSave.Get("anchorContainerRight:%s" % [i], newTaskbar.tempUniqueID)
		taskbars.append(newTaskbar)
		anchorContainerRight.add_child(newTaskbar)
		newTaskbar.LoadBar()
		newTaskbar.AnchorRight()
	
	UtilityHelper.CallOnTimer(0.1, UpdateTaskbars, self)
