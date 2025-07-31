extends Control
class_name BaseFile

## A folder that can be opened and interacted with.
## Files like text/image files are just folders with a different file_type_enum.

enum E_FILE_TYPE {FOLDER, TEXT_FILE, IMAGE, SCENE_FILE, UNKNOWN}
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


func _ready() -> void:
	clickHandler = get_node_or_null("ClickHandler")
	if(clickHandler):
		clickHandler.LeftClick.connect(LeftClicked)
		clickHandler.RightClick.connect(HandleRightClick)
		clickHandler.HoveringStart.connect(HoverStart)
		clickHandler.HoveringEnd.connect(HoverEnd)
		clickHandler.DoubleClick.connect(DoubleClicked)
		clickHandler.NotClicked.connect(NotClicked)
		
	hoverHighlightControl.self_modulate.a = 0
	selectedHighlightControl.visible = false
	fileTitleControl.text = "%s" % szFileName.get_basename()
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
func LeftClicked() -> void:
	show_selected_highlight()

func NotClicked() -> void:
	hide_selected_highlight()

func _get_drag_data(_at_position: Vector2) -> Variant:
	set_drag_preview(fileTexture.get_parent().duplicate())
	return self

# ------

func show_hover_highlight() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(hoverHighlightControl, "self_modulate:a", 1, 0.25).from(0.1)

func hide_hover_highlight() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(hoverHighlightControl, "self_modulate:a", 0, 0.25)

func show_selected_highlight() -> void:
	selectedHighlightControl.visible = true

func hide_selected_highlight() -> void:
	selectedHighlightControl.visible = false

func delete_file() -> void:
	if eFileType == E_FILE_TYPE.FOLDER:
		var delete_path: String = "user://files/%s" % szFilePath
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
				file_manager.UpdateItems()
	else:
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
	NotificationManager.ShowNotification("Moved [color=59ea90][wave freq=7]%s[/wave][/color] to trash!" % szFileName)
	queue_free()

func OpenFile() -> void:
	var filePath: String = "user://files/%s/%s" % [szFilePath, szFileName]
	OS.shell_open(filePath)
	return
func DeleteFile() -> void:
	delete_file()
	return

func HandleRightClick() -> void:
	RClickMenuManager.instance.ShowMenu("Base File Menu", self)
	RClickMenuManager.instance.AddMenuItem("Open Me!", OpenFile, ResourceManager.GetResource("Open"))
	RClickMenuManager.instance.AddMenuItem("Copy", CopyFile, ResourceManager.GetResource("Copy"))
	RClickMenuManager.instance.AddMenuItem("Cut", CutFile, ResourceManager.GetResource("Cut"))
	RClickMenuManager.instance.AddMenuItem("Rename", ShowRename, ResourceManager.GetResource("Edit"))
	RClickMenuManager.instance.AddMenuItem("Delete Me", DeleteFile, ResourceManager.GetResource("Delete"))

	NotificationManager.ShowNotification("Base File Right Click")

	titleEditBox.release_focus()
	titleEditBox.visible = false

func CopyFile() -> void:
	CopyPasteManager.copy_folder(self)

func CutFile() -> void:
	CopyPasteManager.cut_folder(self)

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