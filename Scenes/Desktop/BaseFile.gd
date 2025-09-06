extends Control
class_name BaseFile

## A folder that can be opened and interacted with.
## Files like text/image files are just folders with a different file_type_enum.

enum E_FILE_TYPE {FOLDER, TEXT_FILE, IMAGE, SCENE_FILE, UNKNOWN, APP, PCK}
@export var eFileType: E_FILE_TYPE

@export var fileIcon: Texture2D
@export var fileColor: Color = Color("4efa82")

var szFileName: String
var szFilePath: String # Relative to user://files/

var bMouseOver: bool

@export var hoverHighlightControl: Control
@export var selectedHighlightControl: Control
@export var fileTexture: TextureRect
@export var doubleClickTimer: Timer
@export var titleEditBox: TextEdit
@export var fileTitleControl: RichTextLabel
var clickHandler: HandleClick
static var selectedFiles: Array[Node]
static var selectedFilesOld: Array[Node]

signal RightClickMenuOpened

func _ready() -> void:
	clickHandler = DefaultValues.AddClickHandler(self)
	if(clickHandler):
		clickHandler.LeftClick.connect(LeftClicked)
		clickHandler.RightClickRelease.connect(HandleRightClick)
		clickHandler.HoveringStart.connect(HoverStart)
		clickHandler.HoveringEnd.connect(HoverEnd)
		clickHandler.DragStart.connect(DragStart)
		clickHandler.DragEnd.connect(DragEnd)
		clickHandler.DoubleClick.connect(DoubleClicked)
		clickHandler.NotClickedRelease.connect(NotClicked)
		
	hoverHighlightControl.self_modulate.a = 0
	selectedHighlightControl.visible = false
	fileTitleControl.text = "%s" % szFileName#.get_basename()
	titleEditBox.text = fileTitleControl.text
	
	fileTexture.modulate = fileColor
	fileTexture.texture = fileIcon

func _input(event: InputEvent) -> void:
	if selectedHighlightControl.visible and !titleEditBox.visible:
		if event.is_action_pressed("delete"):
			DeleteFile()
		elif event.is_action_pressed("ui_copy"):
			CopyPasteManager.copy_file(self)
		elif event.is_action_pressed("ui_cut"):
			CopyPasteManager.cut_file(self)
		
		if event.is_action_pressed("ui_up"):
			accept_event()
			get_parent().select_folder_up(self)
		elif event.is_action_pressed("ui_down"):
			accept_event()
			get_parent().select_folder_down(self)
		elif event.is_action_pressed("ui_left"):
			accept_event()
			get_parent().select_folder_left(self)
		elif event.is_action_pressed("ui_right"):
			accept_event()
			get_parent().select_folder_right(self)
		elif event.is_action_pressed("ui_accept"):
			accept_event()
			OpenFile()

func HoverStart() -> void:
	show_hover_highlight()
	bMouseOver = true

func HoverEnd() -> void:
	hide_hover_highlight()
	bMouseOver = false

func DoubleClicked() -> void:
	OpenFile()
	selectedFiles.clear()
func LeftClicked() -> void:
	show_selected_highlight()

var bDragging: bool = false
func DragStart() -> void:
	bDragging = true
	selectedFilesOld.clear()
	selectedFilesOld.append_array(selectedFiles)
	selectedFiles.clear()

func DragEnd() -> void:
	await get_tree().process_frame

func NotClicked() -> void:
	# for file in selectedFiles:
	# 	if(file == self):
	# 		return
	if(!bDragging):
		hide_selected_highlight()
	bDragging = false

func _get_drag_data(_at_position: Vector2) -> Variant:
	var alreadyAdded: bool = false
	for file in selectedFiles:
		if(file == self):
			alreadyAdded = true
	if(!alreadyAdded):
		selectedFiles.append(self)
	set_drag_preview(fileTexture.get_parent().duplicate())
	return selectedFilesOld

# ------

func show_hover_highlight() -> void:
	# var tween: Tween = create_tween()
	# tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# tween.tween_property(hoverHighlightControl, "self_modulate:a", 1, 0.25).from(0.1)
	hoverHighlightControl.self_modulate.a = 1

func hide_hover_highlight() -> void:
	# var tween: Tween = create_tween()
	# tween.set_trans(Tween.TRANS_CUBIC)
	# tween.tween_property(hoverHighlightControl, "self_modulate:a", 0, 0.25)
	hoverHighlightControl.self_modulate.a = 0

func show_selected_highlight() -> void:
	selectedHighlightControl.visible = true
	var alreadyAdded: bool = false
	for file in selectedFiles:
		if(file == self):
			alreadyAdded = true
	if(!alreadyAdded):
		selectedFiles.append(self)

func hide_selected_highlight() -> void:
	selectedHighlightControl.visible = false
	for file in selectedFiles:
		if(file == self):
			selectedFiles.erase(self)

func delete_file() -> void:
	if eFileType == E_FILE_TYPE.FOLDER:
		var delete_path: String = ProjectSettings.globalize_path("%s%s" % [ResourceManager.GetPathToUserFiles(),szFilePath])
		if !DirAccess.dir_exists_absolute(delete_path):
			return
		OS.move_to_trash(delete_path)
		#looking for a file manager currently open with the deleted folder
		#if found, close it
		for file_manager: BaseFileManager in BaseFileManager.masterFileManagerList:
			if file_manager.szFilePath.begins_with(szFilePath) and !(file_manager is DesktopFileManager):
				file_manager.Close()
			elif get_parent() is BaseFileManager and file_manager.szFilePath == get_parent().szFilePath:
				file_manager.delete_file_with_name(szFileName)
				#file_manager.UpdateItems()
	else:
		var delete_path: String = ProjectSettings.globalize_path("%s%s/%s" % [ResourceManager.GetPathToUserFiles(), szFilePath, szFileName])
		if !FileAccess.file_exists(delete_path):
			return
		OS.move_to_trash(delete_path)
		# for file_manager: BaseFileManager in BaseFileManager.masterFileManagerList:
		# 	if file_manager.szFilePath == szFilePath:
		# 		file_manager.delete_file_with_name(szFileName)
		# 		file_manager.SortFolders()
	
	#if szFilePath.is_empty() or (eFileType == E_FILE_TYPE.FOLDER and len(szFilePath.split('/')) == 1):
		#var desktop_file_manager: DesktopFileManager = get_tree().get_first_node_in_group("desktop_file_manager")
		#desktop_file_manager.delete_file_with_name(szFileName)
		#desktop_file_manager.SortFolders()
	# TODO make the color file_type dependent?
	NotificationManager.ShowNotification("Moved [color=59ea90][wave freq=7]%s[/wave][/color] to trash!" % szFileName)
	queue_free()

func OpenThis() -> void:
	var filePath: String = "%s%s/%s" % [ResourceManager.GetPathToUserFiles(), szFilePath, szFileName]
	if(!szFileName.get_extension().is_empty()):
		AppManager.LaunchAppByExt(szFileName.get_extension(), filePath, true)
	else:
		AppManager.LaunchApp("FileExplorer", filePath)
	
func OpenFile() -> void:
	for file: Node in selectedFiles:
		if(file and !file.is_queued_for_deletion() and file is BaseFile):
			var f: BaseFile = file
			f.OpenThis()
	selectedFiles.clear()
	selectedFilesOld.clear()

func DeleteFile() -> void:
	var filemanagerOwner: BaseFileManager# = BaseFileManager.masterFileManagerList[0]
	for filemanager: BaseFileManager in BaseFileManager.masterFileManagerList:
		if(filemanager.szFilePath.begins_with(szFilePath)):
			filemanagerOwner = filemanager
			break

	for file: Node in selectedFiles:
		if(file and !file.is_queued_for_deletion() and file is BaseFile):
			var f: BaseFile = file

			#########################
			if(f.eFileType == E_FILE_TYPE.FOLDER):
				var delete_path: String = ProjectSettings.globalize_path("%s%s" % [ResourceManager.GetPathToUserFiles(),f.szFilePath])
				if !DirAccess.dir_exists_absolute(delete_path):
					return
				OS.move_to_trash(delete_path)
				#looking for a file manager currently open with the deleted folder
				#if found, close it
				for file_manager: BaseFileManager in BaseFileManager.masterFileManagerList:
					if file_manager.szFilePath.begins_with(f.szFilePath) and !(file_manager is DesktopFileManager):
						file_manager.Close()
					#elif get_parent() is BaseFileManager and file_manager.szFilePath == f.get_parent().szFilePath:
					#	file_manager.delete_file_with_name(f.szFileName)
						#file_manager.UpdateItems()
			else:
				var delete_path: String = ProjectSettings.globalize_path("%s%s/%s" % [ResourceManager.GetPathToUserFiles(), f.szFilePath, f.szFileName])
				if !FileAccess.file_exists(delete_path):
					return
				OS.move_to_trash(delete_path)
				#for file_manager: BaseFileManager in BaseFileManager.masterFileManagerList:
				#	if file_manager.szFilePath == f.szFilePath:
				#		file_manager.delete_file_with_name(f.szFileName)
						#file_manager.SortFolders()
				filemanagerOwner.delete_file_with_name(f.szFileName)
			#########################
			
	selectedFiles.clear()
	selectedFilesOld.clear()
	BaseFileManager.RefreshAllFileManagers()
	return

func HandleRightClick() -> void:
	show_selected_highlight()

	RClickMenuManager.instance.ShowMenu("Base File Menu", self, Color.SILVER)
	RClickMenuManager.instance.AddMenuItem("Open Me!", OpenFile, ResourceManager.GetResource("Open"))
	RClickMenuManager.instance.AddMenuItem("Copy", CopyFile, ResourceManager.GetResource("Copy"))
	RClickMenuManager.instance.AddMenuItem("Cut", CutFile, ResourceManager.GetResource("Cut"))
	RClickMenuManager.instance.AddMenuItem("Rename", ShowRename, ResourceManager.GetResource("Edit"))
	RClickMenuManager.instance.AddMenuItem("Rename Popup", ShowRenameDialog, ResourceManager.GetResource("Edit"))
	# RClickMenuManager.instance.AddMenuItem("Delete Me", DeleteFile, ResourceManager.GetResource("Delete"))
	var menuName:String = "Delete file?"
	if(selectedFiles.size()>1):
		menuName = "Delete files?"
	elif(eFileType==E_FILE_TYPE.FOLDER):
		menuName = "Delete folder?"
	elif(eFileType==E_FILE_TYPE.APP):
		menuName = "Delete app shortcut?"
	elif(eFileType==E_FILE_TYPE.IMAGE):
		menuName = "Delete image?"
	RClickMenuManager.instance.AddMenuItem(menuName, AskBeforeDelete, ResourceManager.GetResource("Delete"))

	titleEditBox.release_focus()
	titleEditBox.visible = false

	RightClickMenuOpened.emit()

func CopyFile() -> void:
	#CopyPasteManager.copy_folder(self)
	CopyPasteManager.CopyMultiple(selectedFiles)

func CutFile() -> void:
	#CopyPasteManager.cut_folder(self)
	CopyPasteManager.CutMultiple(selectedFiles)

var grabedFiles: Array[Node]

func AskBeforeDelete() -> void:
	grabedFiles.clear()
	grabedFiles.append_array(selectedFiles)

	var dialog: DialogBox = DialogManager.instance.CreateOKCancelDialog("Delete?", "OK", "Cancel", "Are you sure you want to delete these?", Vector2(0.5, 0.4))
	dialog.Closed.connect((func(d: Dictionary,ourFile:BaseFile) -> void:
		NotificationManager.ShowNotification("Dialogs work? OK pressed: %s or Cancel pressed: %s" % [d["OK"], d["Cancel"]])
		if(d["OK"]):
			ourFile.selectedFiles = ourFile.grabedFiles
			ourFile.DeleteFile()
		return).bind(self)
	)
func ShowRenameDialog() -> void:
	# var dialog: DialogBox = DialogManager.instance.CreateInputDialog("New Name", "OK", "Cancel", "Filename", szFileName, "Enter New File Name", Vector2(0.5,0.3))
	var dialog: DialogBox = DialogManager.instance.CreateInputDialogWithLabel("New Name", "OK", "Cancel", "Filename", szFileName, "Name: ", "Enter New File Name", Vector2(0.5,0.3))
	dialog.Closed.connect(
		(func(d:Dictionary,thisFile:BaseFile) -> void:
			if(d["OK"]):
				thisFile.titleEditBox.text = d["Filename"]
				thisFile.fileTitleControl.text = d["Filename"]
				var folderEdit: FileRenameEdit = thisFile.titleEditBox as FileRenameEdit
				if thisFile.titleEditBox is FileRenameEdit:
					folderEdit.trigger_rename()

				
	).bind(self)
)
#handle renaming controls
func RenameFile() -> void:
	if(!titleEditBox.text.is_empty()):
		await get_tree().process_frame
	
func ShowRename() -> void:
	if(!titleEditBox.visible):
		titleEditBox.visible = true
		titleEditBox.text = fileTitleControl.text.get_basename()
		titleEditBox.grab_focus()
		titleEditBox.select_all()

func _on_folder_title_edit_text_changed() -> void:
	RenameFile()

func _on_title_button_pressed() -> void:
	ShowRename()
