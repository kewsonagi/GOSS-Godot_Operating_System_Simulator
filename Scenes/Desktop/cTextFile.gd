extends BaseFile
class_name cTextFile

func _ready() -> void:
	super._ready()

func OpenFile() -> void:
	var window: FakeWindow
	
	var windowName:String=szFilePath
	var windowID:String="%s/%s" % [szFilePath, szFileName]
	var windowParent:Node=null#get_tree().current_scene
	var windowData: Dictionary = {}

	var filename: String = szFileName;
	if(!szFilePath.is_empty()):
		filename = "%s/%s" % [szFilePath, szFileName]
	
	windowData["Filename"] = filename;
	window = DefaultValues.spawn_window("res://Applications/text_editor.tscn", windowName, windowID, windowData, windowParent)
	#window.title_text = windowName#%"Folder Title".text
	window.titlebarIcon.icon = fileTexture.texture
	
	DefaultValues.AddWindowToTaskbar(window, fileColor, fileTexture.texture)
	return
	
