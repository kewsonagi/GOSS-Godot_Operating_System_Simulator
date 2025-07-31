extends BaseFile
class_name cSceneFile

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
	print(filename)
	window = DefaultValues.spawn_window("res://Scenes/Window/Scene Viewer/SceneViewer.tscn", windowName, windowID, windowData, windowParent)
	#window.title_text = windowName#%"Folder Title".text
	window.titlebarIcon.icon = fileTexture.texture
	
	DefaultValues.AddWindowToTaskbar(window, fileColor, fileTexture.texture)
	return
	
func DeleteFile() -> void:
	var delete_path: String = "user://files/%s/%s" % [szFilePath, szFileName]
	if !FileAccess.file_exists(delete_path):
		return
	OS.move_to_trash(delete_path)
	for file_manager: BaseFileManager in BaseFileManager.masterFileManagerList:
		if file_manager.szFilePath == szFilePath:
			file_manager.delete_file_with_name(szFileName)
			file_manager.SortFolders()

	if szFilePath.is_empty() or (eFileType == E_FILE_TYPE.FOLDER and len(szFilePath.split('/')) == 1):
		var desktop_file_manager: DesktopFileManager = get_tree().get_first_node_in_group("desktop_file_manager")
		desktop_file_manager.delete_file_with_name(szFileName)
		desktop_file_manager.SortFolders()
	# TODO make the color file_type dependent?
	NotificationManager.ShowNotification("Moved [color=59ea90][wave freq=7]%s[/wave][/color] to trash!" % szFileName, NotificationManager.E_NOTIFICATION_TYPE.NORMAL, "Trashed, scene")
	queue_free()

func HandleRightClick() -> void:
	super.HandleRightClick()
	#RClickMenuManager.instance.AddMenuItem("Set Wallpaper", SetWallpaper)

