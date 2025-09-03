extends Control

class_name PinnedTaskbarItem

## A window's taskbar button. Used to minimize/restore a window.
## Also shows which window is selected or minimized via colors.
@export_category("Icon Properties")
@export var texture_rect: TextureRect
@export var selected_background: TextureRect
@export var active_color: Color = Color("6de700")

@export_category("Background Active State Color")
@export var activeBGPanel: Control
@export var rotationControl: Control
@export var activeContainer: Control

@export var pinnedCreationData: Dictionary = {}
@export var pinnedAppManifest: AppManifest
@export var pinnedFilepath: String = ""

signal RightClickedMenuSetup(taskItem: PinnedTaskbarItem)

var clickHandler: HandleClick

func _ready() -> void:
	texture_rect.self_modulate = active_color

	clickHandler = get_node_or_null("ClickHandler")
	if(clickHandler):
		clickHandler.LeftClick.connect(HandleLeftClick)
		clickHandler.RightClick.connect(HandleRightClick)
#		clickHandler.HoveringStart.connect(_on_mouse_entered)
#		clickHandler.HoveringEnd.connect(_on_mouse_exited)

func SetPinnedCreationData(d: Dictionary) -> void:
	pinnedCreationData = d.duplicate(true)

	if(pinnedCreationData.has("Filename")):
		pinnedFilepath = pinnedCreationData["Filename"]
	if(pinnedCreationData.has("manifest")):
		pinnedAppManifest = pinnedCreationData["manifest"]
		texture_rect.texture = pinnedAppManifest.icon

#func _on_mouse_entered() -> void:
	#TweenAnimator.float_bob(self, 6, .4)#(self, 1.3, 0.2)

#func _on_mouse_exited() -> void:
	#TweenAnimator.float_bob(self, 6, .4)#(self, 1.3, 0.2)

func HandleLeftClick() -> void:
	var window: FakeWindow = null
	if(!pinnedFilepath.is_empty()):
		window = AppManager.LaunchAppByExt(pinnedFilepath.get_extension(), pinnedFilepath)
	if(window == null):
		window = AppManager.LaunchApp("FileExplorer", pinnedFilepath)

	if(pinnedAppManifest):
		texture_rect.texture = pinnedAppManifest.icon
	if(pinnedCreationData):
		window.creationData = pinnedCreationData.duplicate(true)

func HandleRightClick() -> void:
	RClickMenuManager.instance.ShowMenu("%s Pin" % pinnedAppManifest.key, self)
	

	RightClickedMenuSetup.emit(self)

func RemovePin() -> void:
	return
func SetRotation(rot: float) -> void:
	rotationControl.rotation_degrees = rot
	if(rot > 95 or rot <-95):
		activeContainer.rotation_degrees = -rot
