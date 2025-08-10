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

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if(data is Array[Node]):
		for file: Node in data as Array[Node]:
			if(file and !file.is_queued_for_deletion() and file is BaseFile):
				var currentFile: BaseFile = file as BaseFile
				if(currentFile.szFilePath == self.szFilePath):
					return false
		return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if(data is Array[Node]):
		var to: String = szFilePath
		CopyPasteManager.CutMultiple(data)
		CopyPasteManager.paste_folder(to)
		BaseFileManager.RefreshAllFileManagers()
		# for file: Node in data as Array[Node]:
		# 	if(file and !file.is_queued_for_deletion() and file is BaseFile):
		# 		var currentFile: BaseFile = file as BaseFile
	
		# #look through children to see if we are dropping an item into ourself
		# #if so, do nothing
		
		# #not an item in this window already, copy or move it
		# # CopyPasteManager.cut_folder(currentFile)
		# # CopyPasteManager.paste_folder(szFilePath)
		# 		var from: String = "%s%s" % [ResourceManager.GetPathToUserFiles(),currentFile.szFilePath]
		# 		var to: String = "%s%s/" % [ResourceManager.GetPathToUserFiles(), szFilePath]
		# 		print(to)
		# #CopyPasteManager.cut_folder(currentFile)
		# #CopyPasteManager.paste_folder(to)
		# 		if(currentFile.eFileType != BaseFile.E_FILE_TYPE.FOLDER):
		# 			from = "%s/%s" % [from, currentFile.szFileName]
		# 		print(from)
		# 		CopyPasteManager.CopyAllFilesOrFolders([from], to, true, true)
		# 		BaseFileManager.RefreshAllFileManagers()
		# CopyAllFilesOrFolders("%s/%s" % [currentFile.szFilePath, currentFile.szFileName], szFilePath)
