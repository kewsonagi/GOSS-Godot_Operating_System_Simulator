extends TaskbarWidget

class_name AppsListWidget

## Bar control that contains a list of running windows in a scroll list
@export var pinnedItemTemplate: PackedScene = preload("res://Scenes/Taskbar/PinnedTaskbarItem.tscn")
@export_category("Bar Properties")
@export var barColor: Color = Color.BLUE_VIOLET
# @export var bgPanel: Panel
@export var taskbarListControl: BoxContainer

var taskItems: Array[TaskbarItem]
var pinnedItems: Array[PinnedTaskbarItem]

func SaveWidget(data: Dictionary) -> void:
	super.SaveWidget(data)
	
	data["%s:numPinnedItems" % widgetID] = pinnedItems.size()
	for i:int in pinnedItems.size():
		data["%spinnedItemData: %s" % [widgetID,i]] = pinnedItems[i].pinnedCreationData

		if(pinnedItems[i].pinnedThumbnail):
			data["%spinnedItemTexture: %s" % [widgetID,i]] = ImageTexture.create_from_image(pinnedItems[i].pinnedThumbnailCopy)
		# var imgPath: String = "%s%spinnedImageTexture: %s.png" % [ResourceManager.GetPathToWindowSettings(), widgetID,i]
		# if(pinnedItems[i].pinnedThumbnail):
		# 	if(pinnedItems[i].pinnedThumbnail.get_image()):
		# 		pinnedItems[i].pinnedThumbnail.get_image().save_png(imgPath)

func LoadWidget(data: Dictionary) -> void:
	super.LoadWidget(data)

	for i:int in pinnedItems.size():
		pinnedItems[i].queue_free()
		taskbarListControl.remove_child(pinnedItems[i])
	pinnedItems.clear()
	if(data.has("%s:numPinnedItems" %  widgetID)):
		var numPins:int = data["%s:numPinnedItems" % widgetID]
		for i:int in numPins:
			var d: Dictionary = data["%spinnedItemData: %s" % [widgetID, i]]
			var tex: Texture2D = config.icon
			#query for the icon of the file that is pinned
			if(d.has("Filename")):
				tex = AppManager.GetAppIconByExt(d["Filename"].get_extension())
			#check for a custom icon from the manifest, if one exists, usually only needed for custom apps or games that have no extension associated with them
			if(d.has("manifest")):
				tex = AppManager.GetAppIcon((d["manifest"] as AppManifest).key)

			#get saved thumbnail if one exists
			if(data.has("%spinnedItemTexture: %s" % [widgetID,i])):
				tex = data["%spinnedItemTexture: %s" % [widgetID,i]]

			var pinnedTask: PinnedTaskbarItem = CreatePinnedTaskbarItem(d, tex)

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

func SetBarColor(c: Color) -> void:
	barColor = c
	self_modulate = c

func HandleRightClick() -> void:
	super.HandleRightClick()
	#RClickMenuManager.instance.AddMenuItem("Change Color", ChangeColor, ResourceManager.GetResource("ColorPicker"))


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
	elif(anchor == E_WIDGET_ANCHOR.TOP):
		SetWidgetLayout(false)
	if(anchor == E_WIDGET_ANCHOR.LEFT):
		SetWidgetLayout(true)
	elif(anchor == E_WIDGET_ANCHOR.RIGHT):
		SetWidgetLayout(true)
	UpdateListItemsRotate()

func MoveWidgetLeft() -> void:
	if(taskbarParent):
		taskbarParent.MoveWidget(self, -1)
func MoveWidgetRight() -> void:
	if(taskbarParent):
		taskbarParent.MoveWidget(self, 1)

func AddTaskItem(taskItem: TaskbarItem) -> void:
	var newItem: TaskbarItem = Desktop.instance.taskbarItemTemplate.instantiate()
	newItem.target_window = taskItem.target_window
	if(taskItem.texture_rect.texture):
		newItem.texture_rect.texture = taskItem.texture_rect.texture#.get_node("TextureMargin/TextureRect").texture = texture
	#taskbar_button.active_color = color
	newItem.foregroundColor = taskItem.foregroundColor

	taskItems.append(newItem)
	taskbarListControl.add_child(newItem)
	newItem.RightClickedMenuSetup.connect(PinTaskbarItemMenu)
	
	UpdateListItemsRotate()

func PinTaskbarItemMenu(taskItem: TaskbarItem) -> void:
	RClickMenuManager.instance.AddMenuItem("Pin Item", PinTaskbarItem.bind(taskItem), ResourceManager.GetResource("Pin"), Color.BLUE_VIOLET)
func PinnedItemMenu(pin: PinnedTaskbarItem) -> void:
	RClickMenuManager.instance.AddMenuItem("Remove Pin", RemovePinnedItem.bind(pin), ResourceManager.GetResource("Delete"), Color.ORANGE_RED)

func PinTaskbarItem(taskItem: TaskbarItem) -> void:
	var pinnedTask: PinnedTaskbarItem = CreatePinnedTaskbarItem(taskItem.target_window.creationData, taskItem.hoverPreviewTexture.texture)
	taskbarParent.SaveBar()
	UpdateListItemsRotate()
	
func CreatePinnedTaskbarItem(d: Dictionary, t: Texture2D) -> PinnedTaskbarItem:
	var pinnedTask: PinnedTaskbarItem = pinnedItemTemplate.instantiate()
	if(pinnedTask):
		pinnedTask.SetPinnedCreationData(d, t)
		pinnedTask.RightClickedMenuSetup.connect(PinnedItemMenu)
		pinnedItems.append(pinnedTask)
		taskbarListControl.add_child(pinnedTask)
		taskbarListControl.move_child(pinnedTask, 0)
	return pinnedTask

func RemovePinnedItem(taskItem: PinnedTaskbarItem) -> void:
	taskbarListControl.remove_child(taskItem)
	pinnedItems.erase(taskItem)
	taskItem.queue_free()
	taskbarParent.SaveBar()

	return

func RemoveTaskItem(taskItem: TaskbarItem) -> void:
	for item: TaskbarItem in taskItems:
		if(item.target_window == taskItem.target_window):
			#taskbarListControl.remove_child(taskItem)
			taskItems.erase(item)
			item.queue_free()
			break

func UpdateListItemsRotate() -> void:
	for newItem: TaskbarItem in taskItems:
		if(anchorPreset == E_WIDGET_ANCHOR.BOTTOM):
			newItem.SetRotation(0)
		if(anchorPreset == E_WIDGET_ANCHOR.TOP):
			newItem.SetRotation(180)
		elif(anchorPreset == E_WIDGET_ANCHOR.LEFT):
			newItem.SetRotation(90)
		elif(anchorPreset == E_WIDGET_ANCHOR.RIGHT):
			newItem.SetRotation(-90)
	
	for newItem: PinnedTaskbarItem in pinnedItems:
		if(anchorPreset == E_WIDGET_ANCHOR.BOTTOM):
			newItem.SetRotation(0)
		if(anchorPreset == E_WIDGET_ANCHOR.TOP):
			newItem.SetRotation(180)
		elif(anchorPreset == E_WIDGET_ANCHOR.LEFT):
			newItem.SetRotation(90)
		elif(anchorPreset == E_WIDGET_ANCHOR.RIGHT):
			newItem.SetRotation(-90)
