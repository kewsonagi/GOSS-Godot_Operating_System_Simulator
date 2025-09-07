extends SelectableGridContainer
class_name BaseFileManager

## The base file manager inherited by desktop file manager and the file manager window.

## The file manager's path (relative to user://files/)
@export var windowTitle: RichTextLabel
@export var szFilePath: String
var directories: PackedStringArray
@export var startingUserDirectory: String = ProjectSettings.globalize_path("user://files/")
@export var baseFile: PackedScene # = preload("res://Scenes/Desktop/TextFile.tscn")
@export var folderFile: PackedScene # = preload("res://Scenes/Desktop/FolderFile.tscn")
@export var appFile: PackedScene
@export var appFileExtension: String = AppManifest.APP_MANIFEST_EXT
@export var packFile: PackedScene
@export var packFileExtension: PackedStringArray = ["tres", "res"]
static var masterFileManagerList: Array[BaseFileManager]
@export var parentWindow: FakeWindow

var fileHistory: Array[String]

signal RightClickMenuOpened

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
	RefreshManager()

func GotoDirectory(path: String) -> void:
	ClearAll()
	directories.clear()
	if(!DirAccess.dir_exists_absolute(path)):
		path = startingUserDirectory
		szFilePath = ""
	directories = DirAccess.get_directories_at(path)
	if (directories):
		for folder_name in directories:
			if szFilePath.is_empty():
				PopulateWithFolder(folder_name, folder_name)
			else:
				PopulateWithFolder(folder_name, "%s/%s" % [szFilePath, folder_name])
	
	directories.clear()
	directories = DirAccess.get_files_at(path)
	for file_name: String in directories:
		var filetype: BaseFile.E_FILE_TYPE = BaseFile.E_FILE_TYPE.UNKNOWN
		if(file_name.get_extension() == appFileExtension):
			filetype = BaseFile.E_FILE_TYPE.APP
		if(packFileExtension.has(file_name.get_extension())):
			filetype = BaseFile.E_FILE_TYPE.PCK
		PopulateWithFile(file_name, szFilePath, filetype)
	
	if(!DirAccess.dir_exists_absolute(path)):
		if(parentWindow):
			parentWindow._on_close_button_pressed()
			return
		# queue_free()
	directories.clear()
	
	UtilityHelper.instance.CallOnDelay(0.05, SortFolders)
	
	if(windowTitle):
		windowTitle.text = "%s" % [szFilePath]

func RefreshManager() -> void:
	GotoDirectory("%s%s" % [startingUserDirectory, szFilePath])

func PopulateWithFolder(fileName: String, path: String) -> void:
	for folder: Node in currentChildren:
		var f: BaseFile = folder as BaseFile
		if f and f.eFileType == BaseFile.E_FILE_TYPE.FOLDER and f.szFilePath == path:
			return
	var folder: BaseFile = folderFile.instantiate()
	var fileType: BaseFile.E_FILE_TYPE = BaseFile.E_FILE_TYPE.FOLDER
	folder.szFileName = fileName
	folder.szFilePath = path
	folder.szStartingDrivePath = startingUserDirectory
	folder.eFileType = fileType
	AddChild(folder)

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
	elif(fileType == BaseFile.E_FILE_TYPE.PCK):
		file = packFile.instantiate()
	else:
		file = baseFile.instantiate()
	#load a thumbnail if one exists for this file extension
	var fileIcon: Texture2D = ResourceManager.GetResourceOrNull(fileName.get_basename())
	if !fileIcon:
		fileIcon = AppManager.GetAppIconByExt(fileName.get_extension())
	if !fileIcon:
		fileIcon = ResourceManager.GetResourceOrNull(fileName.get_extension())
	
	if fileIcon:
		file.fileIcon = fileIcon

	file.szFileName = fileName
	file.szFilePath = path
	file.szStartingDrivePath = startingUserDirectory
	file.eFileType = fileType
	AddChild(file)


## Sorts all folders to their correct positions. 
func SortFolders() -> void:
	# if len(GetChildren()) < 3:
	# 	#UpdateItems()
	# 	return
	# var newChilds: Array[Node] = []
	# for child in GetChildren():
	# 	if child is BaseFile:
	# 		newChilds.append(child)
	# 		RemoveChild(child)
	
	# newChilds.sort_custom(_custom_folder_sort)
	# newChilds.sort_custom(_custom_folders_first_sort)
	# for child in newChilds:
	# 	AddChild(child)
	
	await get_tree().process_frame
	#UpdateItems()

## Creates a new folder.
## Not to be confused with instantiating which adds an existing real folder, this function CREATES one. 
func CreateNewFolder(newFoldername:String) -> void:
	var newFilepath: String = "%s%s" % [startingUserDirectory, szFilePath]
	var new_folder_name: String = UtilityHelper.GetFirstFreeFolderName(newFilepath, newFoldername)
	new_folder_name = UtilityHelper.GetFirstFreeFolderName(newFilepath, new_folder_name)
	
	UtilityHelper.CreateFolder(newFilepath, new_folder_name)
	
	if szFilePath.is_empty():
		PopulateWithFolder(new_folder_name, "%s" % new_folder_name)
		SortFolders()

## Creates a new file.
## Not to be confused with instantiating which adds an existing real folder, this function CREATES one. 
func CreateNewFile(newFilename:String, extension: String, file_type: BaseFile.E_FILE_TYPE) -> void:
	if(!extension.begins_with(".")):
		extension = ".%s" % extension
	var new_file_name: String = "%s%s" % [newFilename, extension]
	var newFilepath: String = "%s%s" % [startingUserDirectory, szFilePath]

	new_file_name = UtilityHelper.GetFirstFreeFileName(newFilepath, new_file_name)
	
	# Just touches the file
	UtilityHelper.CreateFile(newFilepath, new_file_name)
	
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
		return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if(data is Array[Node]):
		var to: String = szFilePath
		CopyPasteManager.CutMultiple(data)
		CopyPasteManager.paste_folder("%s%s" % [startingUserDirectory, to])
		BaseFileManager.RefreshAllFileManagers()



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
	RClickMenuManager.instance.ShowMenu("File Manager Menu", self, Color.ROYAL_BLUE)
	if(BaseFile.selectedFiles.size()>0):
		filesSelected.clear()
		filesSelected.append_array(BaseFile.selectedFiles)
		RClickMenuManager.instance.AddMenuItem("Open Files", OpenFiles, ResourceManager.GetResource("Open"), Color.PALE_GREEN)
		RClickMenuManager.instance.AddMenuItem("Copy", CopyFiles, ResourceManager.GetResource("Copy"), Color.LIGHT_BLUE)
		RClickMenuManager.instance.AddMenuItem("Cut", CutFiles, ResourceManager.GetResource("Cut"), Color.AQUAMARINE)
		RClickMenuManager.instance.AddMenuItem("Rename", ShowRenameDialog, ResourceManager.GetResource("Edit"), Color.CHOCOLATE)
	if(CopyPasteManager.filesList.size()>0):
		RClickMenuManager.instance.AddMenuItem("Paste", Paste, ResourceManager.GetResource("Paste"), Color.LIGHT_YELLOW)
	RClickMenuManager.instance.AddMenuItem("New Folder", NewFolder, ResourceManager.GetResource("Folder"), Color.YELLOW)
	RClickMenuManager.instance.AddMenuItem("New File", NewFile, ResourceManager.GetResource("File"), Color.SLATE_BLUE)
	RClickMenuManager.instance.AddMenuItem("Refresh", Refresh, ResourceManager.GetResource("Refresh"), Color.ORANGE)
	RClickMenuManager.instance.AddMenuItem("Properties", Properties)

	RightClickMenuOpened.emit()

	var item: BaseFile
	if(filesSelected and !filesSelected.is_empty()):
		for i: int in filesSelected.size():
			if(filesSelected[i] and !filesSelected[i].is_queued_for_deletion()):
				item = filesSelected[i]
				item.show_selected_highlight()

func CopyFiles() -> void:
	CopyPasteManager.CopyMultiple(filesSelected)
	var item: BaseFile
	for i: int in filesSelected.size():
		if(filesSelected[i] and !filesSelected[i].is_queued_for_deletion()):
			item = filesSelected[i]
			item.show_selected_highlight()

func CutFiles() -> void:
	CopyPasteManager.CutMultiple(filesSelected)
	var item: BaseFile
	for i: int in filesSelected.size():
		if(filesSelected[i] and !filesSelected[i].is_queued_for_deletion()):
			item = filesSelected[i]
			item.show_selected_highlight()

func ShowRenameDialog() -> void:
	var item: BaseFile
	if(filesSelected.size()>0):
		for file: BaseFile in filesSelected:
			if(file):
				file.ShowRenameDialog()
				break;
	for i: int in filesSelected.size():
		if(filesSelected[i] and !filesSelected[i].is_queued_for_deletion()):
			item = filesSelected[i]
			item.show_selected_highlight()

func OpenFiles() -> void:
	if(filesSelected.size()>0):
		var item: BaseFile
		for i: int in filesSelected.size():
			if(filesSelected[i] and !filesSelected[i].is_queued_for_deletion()):
				item = filesSelected[i]
				item.OpenThis()

func NewFolder() -> void:
	var dialog:DialogBox = DialogManager.instance.CreateInputDialog("New Folder", "Accept", "Cancel", "NewName", "New Folder Copy")
	dialog.Closed.connect((func(d:Dictionary) -> void:
		if(d["Accept"]):
			CreateNewFolder(d["NewName"])
			Refresh()
		)
	)

func Paste() -> void:
	CopyPasteManager.paste_folder("%s%s" % [startingUserDirectory, szFilePath])
	BaseFileManager.RefreshAllFileManagers()

func NewFile() -> void:
	var dialog:DialogBox = DialogManager.instance.CreateInputDialog("New File", "Accept", "Cancel", "NewName", "Untitled.txt")
	dialog.Closed.connect((func(d:Dictionary) -> void:
		if(d["Accept"]):
			CreateNewFile(d["NewName"], "txt", BaseFile.E_FILE_TYPE.TEXT_FILE)
			Refresh()
		)
	)
	

func Refresh() -> void:
	RefreshManager()

func Close() -> void:
	if(parentWindow):
		parentWindow._on_close_button_pressed()

func Properties() -> void:
	RefreshManager()

var filesSelected: Array[Node]
var bDraggingRMB: bool
func CopySelection() -> void:
	CopyPasteManager.CopyMultiple(filesSelected)
	filesSelected.clear()

func CutSelection() -> void:
	CopyPasteManager.CutMultiple(filesSelected)
	filesSelected.clear()


func RightClickedSelection(selection: Array[Node]) -> void:
	filesSelected.clear()
	if(!selection or selection.is_empty()):
		HandleRightClick()
	elif(!selection.is_empty()):
		for file: BaseFile in BaseFile.selectedFiles:
			file.show_selected_highlight()

		filesSelected.append_array(selection)
		RClickMenuManager.instance.ShowMenu("File Manager Menu", self)
		RClickMenuManager.instance.AddMenuItem("Open All", OpenSelection, ResourceManager.GetResource("Open"))
		RClickMenuManager.instance.AddMenuItem("Copy", CopySelection, ResourceManager.GetResource("Copy"))
		RClickMenuManager.instance.AddMenuItem("Cut", CutSelection, ResourceManager.GetResource("Cut"))
		RClickMenuManager.instance.AddMenuItem("Delete items?", AskBeforeDelete, ResourceManager.GetResource("Delete"))

var grabedFiles: Array[Node]

func OpenSelection() -> void:
	for file:Node in filesSelected:
		if(file and file is BaseFile):
			var theFile: BaseFile = file as BaseFile
			theFile.OpenThis()
	filesSelected.clear()

func AskBeforeDelete() -> void:
	grabedFiles.clear()
	grabedFiles.append_array(filesSelected)
	for file:Node in grabedFiles:
		if(file and file is BaseFile):
			var theFile: BaseFile = file as BaseFile
			theFile.show_selected_highlight()

	var dialog: DialogBox = DialogManager.instance.CreateOKCancelDialog("Delete?", "OK", "Cancel", "Are you sure you want to delete these?", Vector2(0.5, 0.4))
	dialog.Closed.connect((func(d: Dictionary,ourself:BaseFileManager) -> void:
		if(d["OK"]):
			var firstValid:BaseFile
			for file:Node in ourself.grabedFiles:
				if(file and file is BaseFile):
					var theFile: BaseFile = file as BaseFile
					theFile.show_selected_highlight()
					firstValid = theFile
			if(firstValid):
				firstValid.DeleteFile()
		return).bind(self)
	)
	filesSelected.clear()


func ClearSelection(items: Array[Node]) -> void:
	for item in items:
		if(item and !item.is_queued_for_deletion() and item is BaseFile):
			var file: BaseFile = item
			file.hide_selected_highlight()
	BaseFile.selectedFiles.clear()
#dragging from an empty space over new items to select
func DragSelectingItems(items: Array[Node], itemsOld: Array[Node]) -> void:
	bDraggingRMB = clickHandler.bRMB
	ClearSelection(itemsOld)
	for item in items:
		if(item is BaseFile):
			var file: BaseFile = item
			file.show_selected_highlight()
#drag ended on the selected items
func DragSelectingItemsEnded(items: Array[Node]) -> void:
	for item in items:
		if(item is BaseFile):
			var file: BaseFile = item
			file.show_selected_highlight()

	if(clickHandler.bRMB):
		if(items.is_empty()):
			HandleRightClick()
		else:
			RightClickedSelection(items)

#dragging a selection of currently selected items
func DragSelectedItemsBegin(items: Array[Node]) -> void:
	#RClickMenuManager.instance.DismissMenu()
	bDraggingRMB = clickHandler.bRMB
	for item in items:
		if(item is BaseFile):
			var file: BaseFile = item
			file.show_selected_highlight()
#dragging around after selecting a group of items
func DraggingSelectedItems(items: Array[Node]) -> void:
	for item in items:
		if(item is BaseFile):
			var file: BaseFile = item
			file.show_selected_highlight()
			file.force_drag(file, file.fileTexture.get_parent().duplicate())
#drag ended and we dropped the items here
func DropItems(items: Array[Node]) -> void:
	for item in items:
		if(item is BaseFile):
			var file: BaseFile = item
			file.show_selected_highlight()
			file.force_drag(file, file.fileTexture.get_parent().duplicate())
