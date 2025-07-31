extends BaseFile
class_name cFolderFile

var parentManager: FileManagerWindow

func _ready() -> void:
	super._ready()

func FindParentManager() -> void:
	#stupid way  to get the parent filemanager, if one exists, to reload or open a new window
	var parentWindow: Node = get_parent()
	if(parentWindow):
		if!(parentWindow is FileManagerWindow):
			parentWindow = get_parent().get_parent()#within a container in a container
			if(parentWindow):
				if!(parentWindow is FileManagerWindow):
					parentWindow = null
	parentManager = parentWindow


func OpenFile() -> void:
	FindParentManager()
	hide_selected_highlight()
	if parentManager and eFileType == E_FILE_TYPE.FOLDER:
		parentManager.reload_window(szFilePath)
	else:
		var window: FakeWindow
	
		var windowName:String=szFilePath
		var windowID:String="%s/%s" % [szFilePath, szFileName]
		var windowParent:Node=null#get_tree().current_scene
		var windowData: Dictionary = {}

		windowData["StartPath"] = szFilePath;
		window = DefaultValues.spawn_window("res://Scenes/Window/File Manager/file_manager_window.tscn", windowName, windowID, windowData,windowParent)
		#window.title_text = windowName#%"Folder Title".text
		window.titlebarIcon.icon = fileTexture.texture
	
		DefaultValues.AddWindowToTaskbar(window, fileColor, fileTexture.texture)
	return
	
func DeleteFile() -> void:
	FindParentManager()

	var delete_path: String = "user://files/%s" % szFilePath
	if !DirAccess.dir_exists_absolute(delete_path):
		return
	OS.move_to_trash(delete_path)
	#looking for a file manager currently open with the deleted folder
	#if found, close it
	for file_manager: BaseFileManager in BaseFileManager.masterFileManagerList:
		if file_manager.szFilePath.begins_with(szFilePath) and (file_manager!=DesktopFileManager):
			file_manager.Close()
		elif parentManager and file_manager.szFilePath == parentManager.szFilePath:
			file_manager.delete_file_with_name(szFileName)
			file_manager.UpdateItems()

	if szFilePath.is_empty() or (eFileType == E_FILE_TYPE.FOLDER and len(szFilePath.split('/')) == 1):
		var desktop_file_manager: DesktopFileManager = get_tree().get_first_node_in_group("desktop_file_manager")
		desktop_file_manager.delete_file_with_name(szFileName)
		desktop_file_manager.SortFolders()
	# TODO make the color file_type dependent?
	NotificationManager.ShowNotification("Moved [color=59ea90][wave freq=7]%s[/wave][/color] to trash!" % szFileName, NotificationManager.E_NOTIFICATION_TYPE.NORMAL, "Trashed folder")
	queue_free()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if(data is BaseFile):
		if((data as BaseFile).szFilePath == self.szFilePath):
			return false
		return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if(data is BaseFile):
		var currentFile: BaseFile = (data as BaseFile)
		#look through children to see if we are dropping an item into ourself
		#if so, do nothing
		
		#not an item in this window already, copy or move it
		# CopyPasteManager.cut_folder(currentFile)
		# CopyPasteManager.paste_folder(szFilePath)
		var from: String = "user://files/%s" % currentFile.szFilePath
		var to: String = "user://files/%s/" % szFilePath
		print(to)
		#CopyPasteManager.cut_folder(currentFile)
		#CopyPasteManager.paste_folder(to)
		if(currentFile.eFileType != BaseFile.E_FILE_TYPE.FOLDER):
			from = "%s/%s" % [from, currentFile.szFileName]
		print(from)
		CopyPasteManager.CopyAllFilesOrFolders([from], to, true, true)
		BaseFileManager.RefreshAllFileManagers()
		# CopyAllFilesOrFolders("%s/%s" % [currentFile.szFilePath, currentFile.szFileName], szFilePath)
