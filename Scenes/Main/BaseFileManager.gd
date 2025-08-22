extends SelectableGridContainer
class_name BaseFileManager

## The base file manager inherited by desktop file manager and the file manager window.

## The file manager's path (relative to user://files/)
@export var windowTitle: RichTextLabel
@export var szFilePath: String
var directories: PackedStringArray
var itemLocations: Dictionary = {}
@export var startingUserDirectory: String = ProjectSettings.globalize_path("user://files/")
@export var baseFile: PackedScene # = preload("res://Scenes/Desktop/TextFile.tscn")
@export var folderFile: PackedScene # = preload("res://Scenes/Desktop/FolderFile.tscn")
@export var appFile: PackedScene
@export var appFileExtension: String = "app"
static var masterFileManagerList: Array[BaseFileManager]
@export var parentWindow: FakeWindow

func _ready() -> void:
	super._ready()

	ClearAll()
	DragSelecting.connect(DragSelectingItems)
	DraggingSelectionEnd.connect(DragSelectingItemsEnded)

	DraggingSelectedBegin.connect(DragSelectedItemsBegin)
	DraggingSelection.connect(DraggingSelectedItems)
	DropSelection.connect(DropItems)
	RightClickEnd.connect(RightClickedSelection)

func populate_file_manager() -> void:
	# for child in GetChildren():
	# 	if child is BaseFile:
	# 		RemoveChild(child)
	# 		child.queue_free()
	
	itemLocations.clear()
	RefreshManager()

func RefreshManager() -> void:
	ClearAll()
	directories.clear()
	directories = DirAccess.get_directories_at("%s%s" % [startingUserDirectory, szFilePath])
	#itemLocations.clear()
	if (directories):
		for folder_name in directories:
			if szFilePath.is_empty():
				PopulateWithFolder(folder_name, folder_name)
			else:
				PopulateWithFolder(folder_name, "%s/%s" % [szFilePath, folder_name])
	
	directories.clear()
	directories = DirAccess.get_files_at("%s%s" % [startingUserDirectory, szFilePath])
	for file_name: String in directories:
		var filetype: BaseFile.E_FILE_TYPE = BaseFile.E_FILE_TYPE.UNKNOWN
		if(file_name.get_extension() == appFileExtension):
			filetype = BaseFile.E_FILE_TYPE.APP
		PopulateWithFile(file_name, szFilePath, filetype)
	
	if(!DirAccess.dir_exists_absolute("%s%s" % [startingUserDirectory, szFilePath])):
		if(parentWindow):
			parentWindow._on_close_button_pressed()
			return
		# queue_free()
	directories.clear()
	
	DefaultValues.CallOnDelay(0.05, SortFolders)
	
	if(windowTitle):
		windowTitle.text = "%s" % [szFilePath]

func PopulateWithFolder(fileName: String, path: String) -> void:
	for folder: Node in currentChildren:
		var f: BaseFile = folder as BaseFile
		if f and f.eFileType == BaseFile.E_FILE_TYPE.FOLDER and f.szFilePath == path:
			return
	var folder: BaseFile = folderFile.instantiate()
	var fileType: BaseFile.E_FILE_TYPE = BaseFile.E_FILE_TYPE.FOLDER
	folder.szFileName = fileName
	folder.szFilePath = path
	folder.eFileType = fileType
	AddChild(folder)
	itemLocations["%s%s" % [path, fileName]] = Vector2(0, 0)

func PopulateWithFile(fileName: String, path: String, fileType: BaseFile.E_FILE_TYPE) -> void:
	#avoid duplicate files
	for folder: Node in currentChildren:
		var f: BaseFile = folder as BaseFile
		if f and f.eFileType == fileType and f.szFilePath == path and f.szFileName == fileName:
			return

	var file: BaseFile
	if(fileType == BaseFile.E_FILE_TYPE.FOLDER):
		file = folderFile.instantiate()
	elif(fileType == BaseFile.E_FILE_TYPE.APP):
		file = appFile.instantiate()
	else:
		file = baseFile.instantiate()
	#load a thumbnail if one exists for this file extension
	var fileIcon: Texture2D = ResourceManager.GetResourceOrNull(fileName.get_basename())
	if !fileIcon:
		fileIcon = ResourceManager.GetResourceOrNull(fileName.get_extension())
	if(!fileIcon):
		fileIcon = AppManager.GetAppIconByExt(fileName.get_extension())
	if(fileIcon):
		file.fileIcon = fileIcon

	file.szFileName = fileName
	file.szFilePath = path
	file.eFileType = fileType
	AddChild(file)
	itemLocations["%s%s" % [path, fileName]] = Vector2(0, 0)


## Sorts all folders to their correct positions. 
func SortFolders() -> void:
	if len(GetChildren()) < 3:
		#UpdateItems()
		return
	var newChilds: Array[Node] = []
	for child in GetChildren():
		if child is BaseFile:
			newChilds.append(child)
			RemoveChild(child)
	
	newChilds.sort_custom(_custom_folder_sort)
	newChilds.sort_custom(_custom_folders_first_sort)
	for child in newChilds:
		AddChild(child)
	
	await get_tree().process_frame
	#UpdateItems()

## Creates a new folder.
## Not to be confused with instantiating which adds an existing real folder, this function CREATES one. 
func CreateNewFolder() -> void:
	var new_folder_name: String = "New Folder"
	var padded_file_path: String # Since I sometimes want the / and sometimes not
	if !szFilePath.is_empty():
		padded_file_path = "%s/" % szFilePath
	if DirAccess.dir_exists_absolute("%s%s%s" % [startingUserDirectory, padded_file_path, new_folder_name]):
		for i in range(2, 1000):
			new_folder_name = "New Folder %d" % i
			if !DirAccess.dir_exists_absolute("%s%s%s" % [startingUserDirectory, padded_file_path, new_folder_name]):
				break
	
	DirAccess.make_dir_absolute("%s%s%s" % [startingUserDirectory, padded_file_path, new_folder_name])
	for file_manager: FileManagerWindow in get_tree().get_nodes_in_group("file_manager_window"):
		if file_manager.szFilePath == szFilePath:
			file_manager.PopulateWithFile(new_folder_name, "%s%s" % [padded_file_path, new_folder_name], BaseFile.E_FILE_TYPE.FOLDER)
			await get_tree().process_frame # Waiting for child to get added...
			SortFolders()
	
	if szFilePath.is_empty():
		PopulateWithFolder(new_folder_name, "%s" % new_folder_name)
		SortFolders()

## Creates a new file.
## Not to be confused with instantiating which adds an existing real folder, this function CREATES one. 
func CreateNewFile(extension: String, file_type: BaseFile.E_FILE_TYPE) -> void:
	if(!extension.begins_with(".")):
		extension = ".%s" % extension
	var new_file_name: String = "New File%s" % extension
	var padded_file_path: String # Since I sometimes want the / and sometimes not
	if !szFilePath.is_empty():
		padded_file_path = "%s/" % szFilePath
	
	if FileAccess.file_exists("%s%s%s" % [startingUserDirectory, padded_file_path, new_file_name]):
		for i in range(2, 1000):
			new_file_name = "New File %d%s" % [i, extension]
			if !FileAccess.file_exists("%s%s%s" % [startingUserDirectory, padded_file_path, new_file_name]):
				break
	
	# Just touches the file
	var _file: FileAccess = FileAccess.open("%s%s%s" % [startingUserDirectory, padded_file_path, new_file_name], FileAccess.WRITE)
	
	for file_manager: FileManagerWindow in get_tree().get_nodes_in_group("file_manager_window"):
		if file_manager.szFilePath == szFilePath:
			file_manager.PopulateWithFile(new_file_name, szFilePath, file_type)
			await get_tree().process_frame # Waiting for child to get added...
			file_manager.SortFolders()
	
	if szFilePath.is_empty():
		if (file_type == BaseFile.E_FILE_TYPE.FOLDER):
			PopulateWithFolder(new_file_name, szFilePath)
		else:
			PopulateWithFile(new_file_name, szFilePath, file_type)
		SortFolders()

## Finds a file/folder based on name and frees it (but doesn't delete it from the actual system)
func delete_file_with_name(file_name: String) -> void:
	for child in GetChildren():
		if !(child is BaseFile):
			continue
		
		if child.szFileName == file_name:
			itemLocations.erase(child.szFileName)
			RemoveChild(child)
			child.queue_free()
	
	await get_tree().process_frame
	#SortFolders()

## Keyboard controls for selecting files.
## Is kind of messy because the file manager can be horizontal or vertical, which changes which direction the next folder is.
func select_folder_up(current_folder: BaseFile) -> void:
	if direction == "Horizontal":
		select_previous_line_folder(current_folder)
	elif direction == "Vertical":
		select_previous_folder(current_folder)

func select_folder_down(current_folder: BaseFile) -> void:
	if direction == "Horizontal":
		select_next_line_folder(current_folder)
	elif direction == "Vertical":
		select_next_folder(current_folder)

func select_folder_left(current_folder: BaseFile) -> void:
	if direction == "Horizontal":
		select_previous_folder(current_folder)
	elif direction == "Vertical":
		select_previous_line_folder(current_folder)

func select_folder_right(current_folder: BaseFile) -> void:
	if direction == "Horizontal":
		select_next_folder(current_folder)
	elif direction == "Vertical":
		select_next_line_folder(current_folder)

func select_next_folder(current_folder: BaseFile) -> void:
	var target_index: int = current_folder.get_index() + 1
	if target_index >= GetChildCount():
		return
	var next_child: Node = GetChild(target_index)
	if next_child is BaseFile:
		current_folder.hide_selected_highlight()
		next_child.show_selected_highlight()

func select_next_line_folder(current_folder: BaseFile) -> void:
	var target_index: int = current_folder.get_index() + nLineCount
	if target_index >= GetChildCount():
		return
	var target_folder: Node = GetChild(target_index)
	if target_folder is BaseFile:
		current_folder.hide_selected_highlight()
		target_folder.show_selected_highlight()

func select_previous_folder(current_folder: BaseFile) -> void:
	var target_index: int = current_folder.get_index() - 1
	if target_index < 0:
		return
	var previous_child: Node = GetChild(target_index)
	if previous_child is BaseFile:
		current_folder.hide_selected_highlight()
		previous_child.show_selected_highlight()

func select_previous_line_folder(current_folder: BaseFile) -> void:
	var target_index: int = current_folder.get_index() - nLineCount
	if target_index < 0:
		return
	var target_folder: Node = GetChild(target_index)
	if target_folder is BaseFile:
		current_folder.hide_selected_highlight()
		target_folder.show_selected_highlight()


## Sorts folders based on their name
func _custom_folder_sort(a: BaseFile, b: BaseFile) -> bool:
	if a.szFileName.to_lower() < b.szFileName.to_lower():
		return true
	return false

## Puts folders first in the array (as opposed to files)
func _custom_folders_first_sort(a: BaseFile, b: BaseFile) -> bool:
	if a.eFileType == BaseFile.E_FILE_TYPE.FOLDER and a.eFileType != b.eFileType:
		return true
	return false

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if(data is Array[Node]):
		for file: Node in data as Array[Node]:
			if(file and !file.is_queued_for_deletion() and file is BaseFile):
				if((file as BaseFile).szFilePath == self.szFilePath):
					return false
		#if((data as BaseFile).szFilePath == self.szFilePath):
		#	return false
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

		# 		for child: Node in currentChildren:
		# 			if (child == currentFile):
		# 				return;
		
		# 		var from: String = "%s%s" % [ResourceManager.GetPathToUserFiles(),currentFile.szFilePath]
		# 		if(currentFile.eFileType != BaseFile.E_FILE_TYPE.FOLDER):
		# 			from = "%s/%s" % [from, currentFile.szFileName]
				

		# 		# if(!currentFile.szFilePath.is_empty()):
		# 		# 	from = "%s%s/%s" % [ResourceManager.GetPathToUserFiles(), f.szFilePath, f.szFileName]
		# 		# else:
		# 		# 	from = "%s%s" % [ResourceManager.GetPathToUserFiles(), f.szFileName]

		# 		CopyPasteManager.CopyAllFilesOrFolders([from], to, true, true)
				# BaseFileManager.RefreshAllFileManagers()
		# CopyAllFilesOrFolders("%s/%s" % [currentFile.szFilePath, currentFile.szFileName], szFilePath)



static func RefreshAllFileManagers() -> void:
	for fileManager: BaseFileManager in masterFileManagerList:
		fileManager.Refresh()

func _enter_tree() -> void:
	masterFileManagerList.append(self)
func _exit_tree() -> void:
	masterFileManagerList.erase(self)
	
func OnDroppedFolders(files: PackedStringArray) -> void:
	CopyPasteManager.CopyAllFilesOrFolders(files)
	BaseFileManager.RefreshAllFileManagers()

func HandleRightClick() -> void:
	RClickMenuManager.instance.ShowMenu("File Manager Menu", self)
	RClickMenuManager.instance.AddMenuItem("Paste", Paste, ResourceManager.GetResource("Paste"))
	RClickMenuManager.instance.AddMenuItem("New Folder", NewFolder, ResourceManager.GetResource("Folder"))
	RClickMenuManager.instance.AddMenuItem("New File", NewFile, ResourceManager.GetResource("File"))
	RClickMenuManager.instance.AddMenuItem("Refresh", Refresh, ResourceManager.GetResource("Refresh"))
	RClickMenuManager.instance.AddMenuItem("Close", Close, ResourceManager.GetResource("Close"))
	RClickMenuManager.instance.AddMenuItem("Properties", Properties)

func NewFolder() -> void:
	CreateNewFolder()
	Refresh()

func Paste() -> void:
	CopyPasteManager.paste_folder(szFilePath)
	BaseFileManager.RefreshAllFileManagers()

func NewFile() -> void:
	CreateNewFile("txt", BaseFile.E_FILE_TYPE.TEXT_FILE)
	Refresh()

func Refresh() -> void:
	RefreshManager()

func Close() -> void:
	parentWindow._on_close_button_pressed()

func Properties() -> void:
	RefreshManager()

var filesSelected: Array[Node]
var bDraggingRMB: bool
func CopySelection() -> void:
	CopyPasteManager.CopyMultiple(filesSelected)
func CutSelection() -> void:
	CopyPasteManager.CutMultiple(filesSelected)

func RightClickedSelection(selection: Array[Node]) -> void:
	if(!selection):
		HandleRightClick()
	elif(!selection.is_empty()):
		filesSelected = selection
		RClickMenuManager.instance.ShowMenu("File Manager Menu", self)
		RClickMenuManager.instance.AddMenuItem("Copy", CopySelection, ResourceManager.GetResource("Copy"))
		RClickMenuManager.instance.AddMenuItem("Cut", CutSelection, ResourceManager.GetResource("Cut"))
		RClickMenuManager.instance.AddMenuItem("Delete items?", AskBeforeDelete, ResourceManager.GetResource("Delete"))

var grabedFiles: Array[Node]

func AskBeforeDelete() -> void:
	grabedFiles.clear()
	grabedFiles.append_array(filesSelected)
	for file:Node in grabedFiles:
		if(file and file is BaseFile):
			var theFile: BaseFile = file as BaseFile
			theFile.show_selected_highlight()

	var dialog: DialogBox = DialogManager.instance.CreateOKCancelDialog("Delete?", "OK", "Cancel", "Are you sure you want to delete these?", Vector2(0.5, 0.4))
	dialog.Closed.connect((func(d: Dictionary,ourself:BaseFileManager):
		if(d["OK"]):
			var firstValid:BaseFile
			for file:Node in ourself.grabedFiles:
				if(file and file is BaseFile):
					var theFile: BaseFile = file as BaseFile
					theFile.show_selected_highlight()
					firstValid = theFile
					#theFile.selectedFiles = ourself.grabedFiles
					#theFile.DeleteFile()
					#break
			if(firstValid):
				firstValid.DeleteFile()
		return).bind(self)
	)

func ClearSelection(items: Array[Node]) -> void:
	for item in items:
		if(item and !item.is_queued_for_deletion() and item is BaseFile):
			var file: BaseFile = item
			file.hide_selected_highlight()
	BaseFile.selectedFiles.clear()
#dragging from an empty space over new items to select
func DragSelectingItems(items: Array[Node], itemsOld: Array[Node]) -> void:
	#RClickMenuManager.instance.DismissMenu()
	bDraggingRMB = clickHandler.bRMB
	ClearSelection(itemsOld)
	for item in items:
		if(item is BaseFile):
			var file: BaseFile = item
			file.show_selected_highlight()
#drag ended on the selected items
func DragSelectingItemsEnded(items: Array[Node]) -> void:
	if(clickHandler.bRMB):
		print("drag select ended with rmb: items: %s" % items)
		if(items.is_empty()):
			HandleRightClick()
		else:
			RightClickedSelection(items)
	for item in items:
		if(item is BaseFile):
			var file: BaseFile = item
			print("dragging selected item ended %s" % file.szFileName)
			file.show_selected_highlight()

#dragging a selection of currently selected items
func DragSelectedItemsBegin(items: Array[Node]) -> void:
	#RClickMenuManager.instance.DismissMenu()
	bDraggingRMB = clickHandler.bRMB
	for item in items:
		if(item is BaseFile):
			var file: BaseFile = item
			print("dragging selected item %s" % file.szFileName)
			file.show_selected_highlight()
#dragging around after selecting a group of items
func DraggingSelectedItems(items: Array[Node]) -> void:
	for item in items:
		if(item is BaseFile):
			var file: BaseFile = item
			file.show_selected_highlight()
			#file._get_drag_data(get_global_mouse_position())
			file.force_drag(file, file.fileTexture.get_parent().duplicate())
#drag ended and we dropped the items here
func DropItems(items: Array[Node]) -> void:
	for item in items:
		if(item is BaseFile):
			var file: BaseFile = item
			print(file)
			file.show_selected_highlight()
			#file._get_drag_data(get_global_mouse_position())
			file.force_drag(file, file.fileTexture.get_parent().duplicate())
