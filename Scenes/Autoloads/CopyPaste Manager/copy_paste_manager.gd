extends Node
## Managed copying and pasting of files and folders.

## The target folder. NOT used for variables since it could be freed by a file manager window!
var target_folder: BaseFile
var target_file: BaseFile

## The target folder's name. Gets emptied after a paste.
var target_folder_name: String
var target_file_name: String

var target_folder_path: String
var target_file_path: String
var target_folder_type: BaseFile.E_FILE_TYPE
var target_file_type: BaseFile.E_FILE_TYPE

enum StateEnum{COPY, CUT}
var state: StateEnum = StateEnum.COPY

# func _ready() -> void:
	# get_viewport().files_dropped.connect(_handle_dropped_folders)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_paste"):
		var selected_window: FakeWindow = GlobalValues.selected_window
		# Paste in desktop if no selected window. Paste in file manager if file manager is selected.
		if selected_window == null:
			paste_folder("")
			return
		
		var file_manager_window: FileManagerWindow = selected_window.get_node_or_null("%File Manager Window")
		if selected_window and file_manager_window != null:
			paste_folder(file_manager_window.szFilePath)

func copy_folder(folder: BaseFile) -> void:
	#if target_folder:
	#	target_folder.modulate.a = 1
	target_folder = folder
	
	target_folder_name = folder.szFileName
	target_folder_path = folder.szFilePath
	target_folder_type = folder.eFileType
	folder.modulate.a = 0.8
	state = StateEnum.COPY
	NotificationManager.ShowNotification("Copied [color=59ea90][wave freq=7]%s[/wave][/color]" % target_folder_name)

func copy_file(file: BaseFile) -> void:
	#if target_file:
	#	target_file.modulate.a = 1
	target_file = file
	
	target_file_name = file.szFileName
	target_file_path = file.szFilePath
	target_file_type = file.eFileType
	file.modulate.a = 0.8
	state = StateEnum.COPY
	NotificationManager.ShowNotification("Copied [color=59ea90][wave freq=7]%s[/wave][/color]" % target_folder_name)

func cut_folder(folder: BaseFile) -> void:
	#if target_folder:
	#	target_folder.modulate.a = 1
	target_folder = folder
	#target_folder.modulate.a = 0.8
	
	target_folder_name = folder.szFileName
	target_folder_path = folder.szFilePath
	target_folder_type = folder.eFileType
	state = StateEnum.CUT
	NotificationManager.ShowNotification("Cutting [color=59ea90][wave freq=7]%s[/wave][/color]" % target_folder_name)

func cut_file(file: BaseFile) -> void:
	#if target_file:
	#	target_file.modulate.a = 1
	target_file = file
	#target_folder.modulate.a = 0.8
	
	target_file_name = file.szFileName
	target_file_path = file.szFilePath
	target_file_type = file.eFileType
	state = StateEnum.CUT
	NotificationManager.ShowNotification("Cutting [color=59ea90][wave freq=7]%s[/wave][/color]" % target_file_name)

## Pastes the folder, caling paste_folder_copy() or paste_folder_cut() depending on the state selected
func paste_folder(to_path: String) -> void:
	if target_folder_name.is_empty():
		NotificationManager.ShowNotification("Error: Nothing to copy")
		return
	
	if state == StateEnum.COPY:
		paste_folder_copy(to_path)
	elif state == StateEnum.CUT:
		paste_folder_cut(to_path)

func paste_folder_copy(to_path: String) -> void:
	var to: String = "user://files/%s/%s" % [to_path, target_folder_name]
	if target_folder_type == BaseFile.E_FILE_TYPE.FOLDER:
		var from: String = "user://files/%s" % target_folder_path
		if from != to:
			DirAccess.make_dir_absolute(to)
			copy_directory_recursively(from, to)
	else:
		var from: String = "user://files/%s/%s" % [target_folder_path, target_folder_name]
		if from != to:
			DirAccess.copy_absolute(from, to)
	
	if target_folder != null:
		target_folder.modulate.a = 1
	if to_path.is_empty():
		var desktop_file_manager: DesktopFileManager = get_tree().get_first_node_in_group("desktop_file_manager")
		desktop_file_manager.delete_file_with_name(target_folder_name)
		instantiate_file_and_sort(desktop_file_manager, to_path)
	else:
		for file_manager: FileManagerWindow in get_tree().get_nodes_in_group("file_manager_window"):
			if file_manager.szFilePath == to_path:
				file_manager.delete_file_with_name(target_folder_name)
				instantiate_file_and_sort(file_manager, to_path)
	
	target_folder_name = ""
	target_folder = null

func paste_folder_cut(to_path: String) -> void:
	var to: String = "user://files/%s/%s" % [to_path, target_folder_name]
	if target_folder_type == BaseFile.E_FILE_TYPE.FOLDER:
		var from: String = "user://files/%s" % target_folder_path
		DirAccess.rename_absolute(from, to)
		for file_manager: FileManagerWindow in get_tree().get_nodes_in_group("file_manager_window"):
			if file_manager.szFilePath.begins_with(target_folder_path):
				file_manager.Close()
			elif file_manager.szFilePath == to_path:
				instantiate_file_and_sort(file_manager, to_path)
	else:
		var from: String = "user://files/%s/%s" % [target_folder_path, target_folder_name]
		DirAccess.rename_absolute(from, to)
		for file_manager: FileManagerWindow in get_tree().get_nodes_in_group("file_manager_window"):
			if file_manager.szFilePath == to_path:
				instantiate_file_and_sort(file_manager, to_path)
	
	if target_folder != null:
		target_folder.get_parent().delete_file_with_name(target_folder_name)
	
	if to_path.is_empty():
		var desktop_file_manager: DesktopFileManager = get_tree().get_first_node_in_group("desktop_file_manager")
		instantiate_file_and_sort(desktop_file_manager, to_path)
	
	target_folder = null

func copy_directory_recursively(dir_path: String, to_path: String) -> void:
	if to_path.begins_with(dir_path):
		NotificationManager.ShowNotification("ERROR: Can't copy a folder into itself!")
		return
	for dir_name in DirAccess.get_directories_at(dir_path):
		DirAccess.make_dir_absolute("%s/%s" % [to_path, dir_name])
		copy_directory_recursively("%s/%s" % [dir_path, dir_name], "%s/%s" % [to_path, dir_name])
	for file_name in DirAccess.get_files_at(dir_path):
		DirAccess.copy_absolute("%s/%s" % [dir_path, file_name], "%s/%s" % [to_path, file_name])

## Instantiates a new file in the file manager then refreshes. Used for adding a single file without causing a full refresh.
func instantiate_file_and_sort(file_manager: BaseFileManager, to_path: String) -> void:
	if target_folder_type == BaseFile.E_FILE_TYPE.FOLDER:
		file_manager.PopulateWithFile(target_folder_name, "%s/%s" % [to_path, target_folder_name], target_folder_type)
	else:
		file_manager.PopulateWithFile(target_folder_name, to_path, target_folder_type)
	file_manager.SortFolders()

#universal copy/cut paste for any files/folder
#handles all sub folders and files
#remember to refresh file managers if moving things around that you can browse in the app
func CopyAllFilesOrFolders(files: PackedStringArray, to: String = "user://files/", override: bool = true, cut: bool = false) -> void:
	for thisFile: String in files:
		var dirToDelete: PackedStringArray
		#print(thisFile)
		var filename: String = thisFile.get_file()#get the end of the path/file, including extension
		
		#check if the filename has no extension, if so this is a folder to copy
		if(filename.is_empty() or filename.get_extension().is_empty()):
			var startingPathOnSystem: String = "%s/" % thisFile.get_base_dir()
			var startingPathLocal: String = to
			# print(startingPathOnSystem)
			# print(startingPathLocal)

			#start with current path
			var pathsToCreate: PackedStringArray = [thisFile.get_file()]
			while (pathsToCreate.size()>0):
				var curPath: String = pathsToCreate.get(0)
				if(cut):
					dirToDelete.append(curPath)
				pathsToCreate.remove_at(0)

				var pathToMake:String = "%s%s" % [startingPathLocal, curPath]
				var pathOnSystem:String = "%s%s" % [startingPathOnSystem, curPath]
				if(!DirAccess.dir_exists_absolute(pathToMake)):
					DirAccess.make_dir_absolute(pathToMake)

				#check for folders in this new directory, if so grab them and add them to the pathsToCreate array
				var newPathsInThisDir: PackedStringArray = DirAccess.get_directories_at(pathOnSystem)
				if(!newPathsInThisDir.is_empty()):
					for nextPath in newPathsInThisDir:
						var fullNextPath: String = "%s/%s" % [curPath, nextPath.get_file()]
						pathsToCreate.append(fullNextPath)
				
				var filesInThisDir: PackedStringArray = DirAccess.get_files_at(pathOnSystem)
				if(!filesInThisDir.is_empty()):
					for nextFile in filesInThisDir:
						var nextFilePath: String = "%s/%s" % [pathToMake, nextFile.get_file()]
						var nextFilePathOnSystem: String = "%s/%s" % [pathOnSystem, nextFile.get_file()]
						if(override or !FileAccess.file_exists(nextFilePath)):
							if(!cut):
								DirAccess.copy_absolute(nextFilePathOnSystem, nextFilePath)
							else:
								DirAccess.rename_absolute(nextFilePathOnSystem, nextFilePath)
			if(override or !FileAccess.file_exists("%s%s" % [to,filename])):
				if(!cut):
					DirAccess.copy_absolute(thisFile, "%s%s" % [to,filename])
				else:
					DirAccess.rename_absolute(thisFile, "%s%s" % [to,filename])
		else:
			if(override or !FileAccess.file_exists("%s%s" % [to,filename])):
				if(!cut):
					DirAccess.copy_absolute(thisFile, "%s%s" % [to,filename])
				else:
					DirAccess.rename_absolute(thisFile, "%s%s" % [to,filename])
		if(cut):
			dirToDelete.reverse()
			for dir in dirToDelete:
				DirAccess.remove_absolute("%s/%s" % [thisFile.get_base_dir(),dir])
			dirToDelete.clear()
	NotificationManager.ShowNotification("Dropped your files into %s" % to, NotificationManager.E_NOTIFICATION_TYPE.NORMAL, "Added files")
