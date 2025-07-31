extends TextEdit

## Handles renaming of a folder.
@export var fileToRenameSelectedIndicator: Control
@export var fileToRename: BaseFile
@export var fileLabelControl: RichTextLabel

func _input(event: InputEvent) -> void:
	if(!visible):return
	
	if event.is_action_pressed("rename") and fileToRenameSelectedIndicator.visible:
		show_rename()
	
	if(!fileToRenameSelectedIndicator.visible and !self.has_focus()):
		trigger_rename()
		self.visible = false
	
	# if !get_parent().visible:
	# 	return
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("Enter"):
		accept_event()
		trigger_rename()
	
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("Escape"):
		cancel_rename()
	
	# if event is InputEventMouseButton and event.is_pressed():
	# 	var evLocal: InputEvent = make_input_local(event)
	# 	if !Rect2(Vector2(0,0), size).has_point(evLocal.position):
	# 		cancel_rename()

func show_rename() -> void:
	#get_parent().visible = true
	grab_focus()
	#text = %"Folder Title".text.trim_prefix("[center]").split(".")[0]
	select_all()

func trigger_rename() -> void:
	if text.contains('/') or text.contains('\\') or text.contains('¥') or text.contains('₩'):
		NotificationManager.ShowNotification("Error: File name can't include slashes!", NotificationManager.E_NOTIFICATION_TYPE.ERROR, "Error")
		self.visible = false
		return
	
	if text.is_empty():
		NotificationManager.ShowNotification("Error: File name can't be empty!", NotificationManager.E_NOTIFICATION_TYPE.ERROR, "Error")
		self.visible = false
		return
	
	#get_parent().visible = false
	var folder: BaseFile = fileToRename
	
	if folder.eFileType != BaseFile.E_FILE_TYPE.FOLDER:
		var old_folder_name: String = folder.szFileName
		print(old_folder_name)
		var new_folder_name: String = "%s.%s" % [text, folder.szFileName.split('.')[-1]]
		print(new_folder_name)
		if FileAccess.file_exists("user://files/%s/%s" % [folder.szFilePath, new_folder_name]):
			cancel_rename()
			NotificationManager.ShowNotification("That file already exists!", NotificationManager.E_NOTIFICATION_TYPE.ERROR, "Error")
			return
		folder.szFileName = new_folder_name
		DirAccess.rename_absolute("user://files/%s/%s" % [folder.szFilePath, old_folder_name], "user://files/%s/%s" % [folder.szFilePath, folder.szFileName])
		fileLabelControl.text = "%s" % folder.szFileName.get_basename()
		
		FileManagerWindow.RefreshAllFileManagers()
		# if folder.get_parent() is DesktopFileManager:
		# 	folder.get_parent().sort_folders()
		# else:
		# 	# Reloads open windows
		# 	for file_manager: FileManagerWindow in get_tree().get_nodes_in_group("file_manager_window"):
		# 		if file_manager.szFilePath == folder.szFilePath:
		# 			file_manager.sort_folders()
		for text_editor in get_tree().get_nodes_in_group("text_editor_window"):
			if text_editor.szFileName == "%s/%s" % [folder.szFilePath, old_folder_name]:
				text_editor.szFileName = "%s/%s" % [folder.szFilePath, folder.szFileName]
			elif text_editor.szFileName == old_folder_name: # In desktop
				text_editor.szFileName = folder.szFileName 
	
	elif folder.eFileType == BaseFile.E_FILE_TYPE.FOLDER:
		var old_folder_name: String = folder.szFileName
		var old_folder_path: String = folder.szFilePath
		
		if old_folder_path.contains("/"):
			var new_folder_path: String = "%s%s" % [folder.szFilePath.trim_suffix(old_folder_name), text]
			if DirAccess.dir_exists_absolute("user://files/%s" % new_folder_path):
				cancel_rename()
				NotificationManager.ShowNotification("That folder already exists!", NotificationManager.E_NOTIFICATION_TYPE.ERROR, "Error")
				return
			folder.szFilePath = new_folder_path
		else:
			if DirAccess.dir_exists_absolute("user://files/%s" % text):
				cancel_rename()
				NotificationManager.ShowNotification("That folder already exists!", NotificationManager.E_NOTIFICATION_TYPE.ERROR, "Error")
				return
			folder.szFilePath = text
		folder.szFileName = text
		fileLabelControl.text = "%s" % folder.szFileName
		DirAccess.rename_absolute("user://files/%s" % old_folder_path, "user://files/%s" % folder.szFilePath)
		
		if folder.get_parent() is DesktopFileManager:
			folder.get_parent().sort_folders()
		for file_manager: FileManagerWindow in get_tree().get_nodes_in_group("file_manager_window"):
			if file_manager.szFilePath.begins_with(old_folder_path):
				file_manager.szFilePath = file_manager.szFilePath.replace(old_folder_path, folder.szFilePath)
				file_manager.reload_window("")
			elif file_manager.szFilePath == folder.szFilePath.trim_suffix("/%s" % folder.szFileName):
				file_manager.sort_folders()
	
	text = ""
	self.release_focus()
	self.visible = false

func cancel_rename() -> void:
	#get_parent().visible = false
	text = ""
	self.release_focus()
	visible = false
