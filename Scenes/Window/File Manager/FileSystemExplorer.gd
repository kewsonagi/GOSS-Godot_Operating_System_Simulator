extends BaseFileManager
class_name FileManagerWindow

## The file manager window.

func _ready() -> void:
	if(parentWindow and parentWindow.creationData.has("StartPath")):
		szFilePath = parentWindow.creationData["StartPath"]
		parentWindow.resized.connect(UpdateItems)
	elif(parentWindow.creationData.has("Filename")):
		szFilePath = parentWindow.creationData["Filename"]
		parentWindow.resized.connect(UpdateItems)
	else:
		szFilePath = ResourceManager.GetPathToUserFiles()
	
	super._ready()
	clickHandler.BackButtonPressed.connect(_on_back_button_pressed)
	populate_file_manager()
	UtilityHelper.instance.CallOnDelay(0.05, RefreshManager)

func reload_window(folder_path: String) -> void:
	# Reload the same path if not given folder_path
	if !folder_path.is_empty():
		szFilePath = folder_path
	
	# for child in GetChildren():
	# 	if child is BaseFile:
	# 		RemoveChild(child)
	# 		child.queue_free()
	#ClearAll()
	if(szFilePath != folder_path):
		ClearAll()
	Refresh()
	#populate_file_manager()
	
	#TODO make this less dumb
	if(windowTitle):
		windowTitle.text = "%s" % [szFilePath]
	
	if(parentWindow):
		parentWindow.select_window(true)

func HandleRightClick() -> void:
	super.HandleRightClick()
	RClickMenuManager.instance.AddMenuItem("Close Window", Close, ResourceManager.GetResource("Close"), Color.INDIAN_RED)

## Goes to the folder above the currently shown one. Can't go higher than user://files/
func _on_back_button_pressed() -> void:
	#TODO move it to a position that's less stupid
	var split_path: PackedStringArray = szFilePath.split("/")
	if split_path.size() <= 1:
		return

	split_path.remove_at(split_path.size() - 1)
	szFilePath = "/".join(split_path)
	
	reload_window(szFilePath)
