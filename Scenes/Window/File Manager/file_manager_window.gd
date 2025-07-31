extends BaseFileManager
class_name FileManagerWindow

## The file manager window.

func _ready() -> void:
	if(parentWindow.creationData.has("StartPath")):
		szFilePath = parentWindow.creationData["StartPath"]
	populate_file_manager()
	parentWindow.resized.connect(UpdateItems)

func reload_window(folder_path: String) -> void:
	# Reload the same path if not given folder_path
	if !folder_path.is_empty():
		szFilePath = folder_path
	
	# for child in GetChildren():
	# 	if child is BaseFile:
	# 		RemoveChild(child)
	# 		child.queue_free()
	#ClearAll()
	Refresh()
	#populate_file_manager()
	
	#TODO make this less dumb
	if(windowTitle):
		windowTitle.text = "%s" % [szFilePath]
	parentWindow.select_window(true)

# func close_window() -> void:
# 	$"../.."._on_close_button_pressed()

## Goes to the folder above the currently shown one. Can't go higher than user://files/
func _on_back_button_pressed() -> void:
	#TODO move it to a position that's less stupid
	var split_path: PackedStringArray = szFilePath.split("/")
	if split_path.size() <= 1:
		return

	split_path.remove_at(split_path.size() - 1)
	szFilePath = "/".join(split_path)
	
	reload_window(szFilePath)
