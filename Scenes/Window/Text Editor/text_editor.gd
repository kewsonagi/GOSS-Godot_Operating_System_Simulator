extends CodeEdit

## The text editor window. Is actually a CodeEdit to support line numbers for each row.

#@onready var window: FakeWindow = $"../.."
@export var parentWindow: FakeWindow

var text_edited: bool
var szFileName: String : 
	set(value):
		szFileName = value

func _ready() -> void:
	if(parentWindow.creationData.has("Filename")):
		populate_text(parentWindow.creationData["Filename"])

	parentWindow.selected.connect(_on_window_selected)
	
	adjust_menu_options()

func _input(event: InputEvent) -> void:
	if !parentWindow.is_selected:
		return
	
	if event.is_action_pressed("save"):
		accept_event()
		save_file()

func populate_text(path: String) -> void:
	szFileName = path
	var file: FileAccess = FileAccess.open("user://files/%s" % szFileName, FileAccess.READ)
	text = file.get_as_text()

func _on_text_changed() -> void:
	if text_edited:
		return
	
	text_edited = true
	parentWindow.titleText.text += "*"

func save_file() -> void:
	if !text_edited:
		return
	
	if !FileAccess.file_exists("user://files/%s" % szFileName):
		NotificationManager.ShowNotification("[color=fc6c64]Couldn't save text file: File no longer exists")
		return
	
	var file: FileAccess = FileAccess.open("user://files/%s" % szFileName, FileAccess.WRITE)
	file.store_string(text)
	
	parentWindow.titleText.text = parentWindow.titleText.text.trim_suffix("*")
	text_edited = false
	
	NotificationManager.ShowNotification("Saved!", NotificationManager.E_NOTIFICATION_TYPE.INFO)

func _on_window_selected(selected: bool) -> void:
	if selected:
		grab_focus()
	else:
		release_focus()

## Adjusts right click options for this TextEdit.
## Removes unnecessary options and adds one for word wrap.
func adjust_menu_options() -> void:
	var menu: PopupMenu = get_menu()
	
	menu.remove_item(5)
	menu.remove_item(10)
	menu.remove_item(10)
	menu.remove_item(10)
	
	menu.add_check_item("Word Wrap")
	menu.set_item_checked(-1, true)
	
	menu.id_pressed.connect(_set_word_wrap)

func _set_word_wrap(id: int) -> void:
	if id == 10:
		var menu: PopupMenu = get_menu()
		if wrap_mode == TextEdit.LINE_WRAPPING_NONE:
			wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			menu.set_item_checked(-1, true)
		else:
			wrap_mode = TextEdit.LINE_WRAPPING_NONE
			menu.set_item_checked(-1, false)
