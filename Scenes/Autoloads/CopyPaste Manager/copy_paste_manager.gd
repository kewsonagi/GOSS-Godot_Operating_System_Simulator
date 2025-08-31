extends Node
## Managed copying and pasting of files and folders.

## The target folder. NOT used for variables since it could be freed by a file manager window!
var target_folder: BaseFile

## The target folder's name. Gets emptied after a paste.
var target_folder_name: String

var target_folder_path: String
var target_folder_type: BaseFile.E_FILE_TYPE
var filesList: Array[Node]
enum StateEnum{COPY, CUT}
var state: StateEnum = StateEnum.COPY

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
	filesList.clear()
	filesList.append(folder)
	folder.modulate.a = 0.8
	state = StateEnum.COPY
	if(filesList.is_empty()):
		NotificationManager.ShowNotification("Copied [color=59ea90][wave freq=7]%s[/wave][/color]" % target_folder_name)

func copy_file(file: BaseFile) -> void:
	copy_folder(file)

func CopyMultiple(files: Array[Node]) -> void:
	filesList.clear()
	filesList.append_array(files)
	state = StateEnum.COPY
func CutMultiple(files: Array[Node]) -> void:
	filesList.clear()
	filesList.append_array(files)
	state = StateEnum.CUT

func cut_folder(folder: BaseFile) -> void:
	filesList.clear()
	filesList.append(folder)
	state = StateEnum.CUT
	if(filesList.is_empty()):
		NotificationManager.ShowNotification("Cutting [color=59ea90][wave freq=7]%s[/wave][/color]" % target_folder_name)

func cut_file(file: BaseFile) -> void:
	cut_folder(file)

## Pastes the folder, caling paste_folder_copy() or paste_folder_cut() depending on the state selected
func paste_folder(to_path: String) -> void:
	var toPath: String = "%s%s/" % [ResourceManager.GetPathToUserFiles(), to_path]
	var packedFiles: PackedStringArray = []
	var fromPath: String;

	if target_folder_name.is_empty() and filesList.is_empty():
		NotificationManager.ShowNotification("Error: Nothing to copy")
		return
	
	if(filesList and !filesList.is_empty()):
		for file in filesList:
			if(file and !file.is_queued_for_deletion() and file is BaseFile):
				var f: BaseFile = file
				if(f):
					if(f.eFileType == BaseFile.E_FILE_TYPE.FOLDER):
						fromPath = "%s%s" % [ResourceManager.GetPathToUserFiles(), f.szFilePath]
					else:
						if(!f.szFilePath.is_empty()):
							fromPath = "%s%s/%s" % [ResourceManager.GetPathToUserFiles(), f.szFilePath, f.szFileName]
						else:
							fromPath = "%s%s" % [ResourceManager.GetPathToUserFiles(), f.szFileName]
					packedFiles.append(fromPath)
	
	if state == StateEnum.COPY:
		CopyAllFilesOrFolders(packedFiles, toPath, true, false)
					
	elif state == StateEnum.CUT:
		CopyAllFilesOrFolders(packedFiles, toPath, true, true)
	filesList.clear()

#universal copy/cut paste for any files/folder
#handles all sub folders and files
#remember to refresh file managers if moving things around that you can browse in the app
func CopyAllFilesOrFolders(files: PackedStringArray, to: String = "user://files/", override: bool = true, cut: bool = false) -> void:
	for thisFile: String in files:
		var dirToDelete: PackedStringArray
		var filename: String = thisFile.get_file()#get the end of the path/file, including extension
		
		#check if the filename has no extension, if so this is a folder to copy
		if(filename.is_empty() or filename.get_extension().is_empty()):
			var startingPathOnSystem: String = "%s/" % thisFile.get_base_dir()
			var startingPathLocal: String = to

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
