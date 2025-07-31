extends BaseFileManager
class_name DesktopFileManager

## The desktop file manager.
@export var defaultFilesLocation: String

func _ready() -> void:
	var user_dir: DirAccess = DirAccess.open("user://")
	if !user_dir.dir_exists("files"):
		# Can't just use absolute paths due to https://github.com/godotengine/godot/issues/82550
		# Also DirAccess can't open on res:// at export, but FileAccess does...
		user_dir.make_dir_recursive("files/Welcome Folder")
		user_dir.make_dir_recursive("files/Wallpapers")
		copy_from_res("res://Default Files/Welcome.txt", "user://files/Welcome Folder/Welcome.txt")
		copy_from_res("res://Default Files/Credits.txt", "user://files/Welcome Folder/Credits.txt")
		copy_from_res("res://Default Files/GodotOS Handbook.txt", "user://files/Welcome Folder/GodotOS Handbook.txt")
		copy_from_res("res://Default Files/default wall.webp", "user://files/Wallpapers/default wall.webp")
		
		#Additional wallpapers
		copy_from_res("res://Default Files/wallpaper_chill.webp", "user://files/Wallpapers/chill.webp")
		copy_from_res("res://Default Files/wallpaper_minimalism.webp", "user://files/Wallpapers/minimalism.webp")

		var wallpaper: Wallpaper = $"/root/Control/Wallpaper"
		wallpaper.apply_wallpaper_from_path("files/Wallpapers/default wall.webp")
		
		copy_from_res("res://Default Files/default wall.webp", "user://default wall.webp")
		DefaultValues.wallpaper_name = "default wall.webp"
		DefaultValues.save_state()
		NotificationManager.ShowNotification("Getting things ready...", NotificationManager.E_NOTIFICATION_TYPE.NORMAL, "Welcome!")
		NotificationManager.ShowNotification("Added some dummy files on your desktop to play with", NotificationManager.E_NOTIFICATION_TYPE.INFO, "Info")
		NotificationManager.ShowNotification("Don't forget you can drop your own files in here to play with", NotificationManager.E_NOTIFICATION_TYPE.NORMAL, "Enjoy")
		#CopyPasteManager.CopyAllFilesOrFolders([defaultFilesLocation])
	
	super._ready();
	get_window().size_changed.connect(UpdateItems)
	get_window().focus_entered.connect(_on_window_focus)

func copy_from_res(from: String, to: String) -> void:
	var file_from: FileAccess = FileAccess.open(from, FileAccess.READ)
	var file_to: FileAccess = FileAccess.open(to, FileAccess.WRITE)
	file_to.store_buffer(file_from.get_buffer(file_from.get_length()))
	
	file_from.close()
	file_to.close()

## Checks if any files were changed on the desktop, and populates the file manager again if so.
func _on_window_focus() -> void:
	var current_file_names: Array[String] = []
	for child in GetChildren():
		# if !(child is FakeFolder):
		if !(child is BaseFile):
			continue
		
		# current_file_names.append(child.folder_name)
		current_file_names.append(child.szFileName)
	
	var new_file_names: Array[String] = []
	for file_name in DirAccess.get_files_at("user://files/"):
		new_file_names.append(file_name)
	for folder_name in DirAccess.get_directories_at("user://files/"):
		new_file_names.append(folder_name)
	
	if current_file_names.size() != new_file_names.size():
		Refresh()
		return
	
	for file_name in new_file_names:
		if !current_file_names.has(file_name):
			Refresh()
			return

func HandleRightClick() -> void:
	RClickMenuManager.instance.ShowMenu("Desktop Menu", self)
	RClickMenuManager.instance.AddMenuItem("Paste", Paste, ResourceManager.GetResource("Paste"))
	RClickMenuManager.instance.AddMenuItem("New Folder", NewFolder, ResourceManager.GetResource("Folder"))
	RClickMenuManager.instance.AddMenuItem("New File", NewFile, ResourceManager.GetResource("File"))
	RClickMenuManager.instance.AddMenuItem("Refresh", Refresh, ResourceManager.GetResource("Refresh"))
	RClickMenuManager.instance.AddMenuItem("Properties", Properties)

func Paste() -> void:
	CopyPasteManager.paste_folder(szFilePath)

func NewFolder() -> void:
	CreateNewFolder()

func NewFile() -> void:
	CreateNewFile("txt", BaseFile.E_FILE_TYPE.TEXT_FILE)

func Refresh() -> void:
	RefreshManager()

func Properties() -> void:
	RefreshManager()


func _enter_tree() -> void:
	masterFileManagerList.append(self)
	get_viewport().files_dropped.connect(OnDroppedFolders)
func _exit_tree() -> void:
	get_viewport().files_dropped.disconnect(OnDroppedFolders)
	masterFileManagerList.erase(self)

func OnDroppedFolders(files: PackedStringArray) -> void:
	#default to the desktop path
	var filepathTo: String = "user://files/"

	#look to see if the pointer is inside a filemanager window
	for filemanager in masterFileManagerList:
		var window: FakeWindow = filemanager.parentWindow

		if(window):
			if(window.is_selected):
				filepathTo = "user://files/%s/" % filemanager.szFilePath
			var pos: Vector2 = window.global_position
			var windowSize: Vector2 = window.size
			var mousePos: Vector2 = get_global_mouse_position()
			#if the mouse pointer is inside this window, add the dropped file here
			if(mousePos.x > pos.x && mousePos.x < pos.x+windowSize.x && mousePos.y > pos.y && mousePos.y < pos.y+windowSize.y):
				filepathTo = "user://files/%s/" % filemanager.szFilePath

	CopyPasteManager.CopyAllFilesOrFolders(files, filepathTo)
		# get_tree().get_first_node_in_group("desktop_file_manager").populate_file_manager()
	RefreshAllFileManagers()
