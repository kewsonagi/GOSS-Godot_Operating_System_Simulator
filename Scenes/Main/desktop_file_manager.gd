extends BaseFileManager
class_name DesktopFileManager

## The desktop file manager.
@export var defaultFilesLocation: String

func _ready() -> void:
	await get_tree().process_frame
	var user_dir: DirAccess = DirAccess.open(ProjectSettings.globalize_path("user://"))
	if !user_dir.dir_exists("files"):
		# Can't just use absolute paths due to https://github.com/godotengine/godot/issues/82550
		# Also DirAccess can't open on res:// at export, but FileAccess does...
		user_dir.make_dir_recursive("files/Welcome Folder")
		user_dir.make_dir_recursive("files/Wallpapers")
		copy_from_res("res://Default Files/Welcome.txt", ProjectSettings.globalize_path("user://files/Welcome Folder/Welcome.txt"))
		copy_from_res("res://Default Files/Credits.txt", ProjectSettings.globalize_path("user://files/Welcome Folder/Credits.txt"))
		copy_from_res("res://Default Files/GodotOS Handbook.txt", ProjectSettings.globalize_path("user://files/Welcome Folder/GodotOS Handbook.txt"))
		copy_from_res("res://Default Files/default wall.webp", ProjectSettings.globalize_path("user://files/Wallpapers/default wall.webp"))
		
		#Additional wallpapers
		copy_from_res("res://Default Files/wallpaper_chill.webp", ProjectSettings.globalize_path("user://files/Wallpapers/chill.webp"))
		copy_from_res("res://Default Files/wallpaper_minimalism.webp", ProjectSettings.globalize_path("user://files/Wallpapers/minimalism.webp"))

		var wallpaper: Wallpaper = DefaultValues.wallpaper
		wallpaper.apply_wallpaper_from_path("files/Wallpapers/default wall.webp")
		
		copy_from_res("res://Default Files/default wall.webp", ProjectSettings.globalize_path("user://default wall.webp"))
		DefaultValues.wallpaper_name = "default wall.webp"
		DefaultValues.save_state()
		NotificationManager.ShowNotification("Getting things ready...", NotificationManager.E_NOTIFICATION_TYPE.NORMAL, "Welcome!")
		NotificationManager.ShowNotification("Added some dummy files on your desktop to play with", NotificationManager.E_NOTIFICATION_TYPE.INFO, "Info")
		NotificationManager.ShowNotification("Don't forget you can drop your own files in here to play with", NotificationManager.E_NOTIFICATION_TYPE.NORMAL, "Enjoy")
		#CopyPasteManager.CopyAllFilesOrFolders([defaultFilesLocation])
	
	super._ready();
	
	#if(!BaseFileManager.masterFileManagerList.has(self as BaseFileManager)):
	#BaseFileManager.masterFileManagerList.append(self)
	get_window().size_changed.connect(UpdateItems)
	get_window().focus_entered.connect(_on_window_focus)
	populate_file_manager()

	UtilityHelper.instance.CallOnDelay(0.05, RefreshManager)

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
	for file_name in DirAccess.get_files_at(ResourceManager.GetPathToUserFiles()):
		new_file_names.append(file_name)
	for folder_name in DirAccess.get_directories_at(ResourceManager.GetPathToUserFiles()):
		new_file_names.append(folder_name)
	
	if current_file_names.size() != new_file_names.size():
		Refresh()
		return
	
	for file_name in new_file_names:
		if !current_file_names.has(file_name):
			Refresh()
			return

func HandleRightClick() -> void:
	RClickMenuManager.instance.ShowMenu("Desktop Menu", self, Color.ORCHID)
	if(BaseFile.selectedFiles.size()>0):
		RClickMenuManager.instance.AddMenuItem("Open Files", OpenFiles, ResourceManager.GetResource("Open"), Color.PALE_GREEN)
		RClickMenuManager.instance.AddMenuItem("Copy", CopyFiles, ResourceManager.GetResource("Copy"), Color.LIGHT_BLUE)
	if(CopyPasteManager.filesList.size()>0):
		RClickMenuManager.instance.AddMenuItem("Paste", Paste, ResourceManager.GetResource("Paste"), Color.LIGHT_YELLOW)
	RClickMenuManager.instance.AddMenuItem("New Folder", NewFolder, ResourceManager.GetResource("Folder"), Color.YELLOW)
	RClickMenuManager.instance.AddMenuItem("New File", NewFile, ResourceManager.GetResource("File"), Color.SLATE_BLUE)
	RClickMenuManager.instance.AddMenuItem("Refresh", Refresh, ResourceManager.GetResource("Refresh"), Color.ORANGE)
	RClickMenuManager.instance.AddMenuItem("Properties", Properties)

	RightClickMenuOpened.emit()

func Copy() -> void:
	CopyPasteManager.CopyMultiple(BaseFile.selectedFiles)

func OpenFiles() -> void:
	for file: BaseFile in BaseFile.selectedFiles:
		file.OpenThis()

func Paste() -> void:
	CopyPasteManager.paste_folder(szFilePath)
	BaseFileManager.RefreshAllFileManagers()

# func NewFolder() -> void:
# 	CreateNewFolder()
# 	var dialog:DialogBox = DialogManager.instance.CreateInputDialog("New Folder", "Accept", "Cancel", "NewName", "New Folder Copy")
# 	dialog.Closed.connect((func(d:Dictionary) -> void:
# 		if(d["OK"]):
# 			CreateNewFolder(d["NewName"])
# 			Refresh()
# 		)
# 	)

# func NewFile() -> void:
# 	CreateNewFile("txt", BaseFile.E_FILE_TYPE.TEXT_FILE)
# 	var dialog:DialogBox = DialogManager.instance.CreateInputDialog("New File", "Accept", "Cancel", "NewName", "Untitled.txt")
# 	dialog.Closed.connect((func(d:Dictionary) -> void:
# 		if(d["OK"]):
# 			CreateNewFile(d["NewName"], "txt", BaseFile.E_FILE_TYPE.TEXT_FILE)
# 			Refresh()
# 		)
# 	)

func Refresh() -> void:
	RefreshManager()

func Properties() -> void:
	RefreshManager()


func _enter_tree() -> void:
	#masterFileManagerList.append(self)
	super._enter_tree()
	get_viewport().files_dropped.connect(OnDroppedFolders)
func _exit_tree() -> void:
	super._exit_tree()
	get_viewport().files_dropped.disconnect(OnDroppedFolders)
	#masterFileManagerList.erase(self)

func OnDroppedFolders(files: PackedStringArray) -> void:
	#default to the desktop path
	var managersWithin: Array[BaseFileManager] = [self]
	var filepathTo: String = ResourceManager.GetPathToUserFiles()#"user://files/"

	#look to see if the pointer is inside a filemanager window
	for filemanager in masterFileManagerList:
		var window: FakeWindow = filemanager.parentWindow

		if(window):
			if(window.is_selected):
				filepathTo = "%s%s/" % [ResourceManager.GetPathToUserFiles(),filemanager.szFilePath]
			var pos: Vector2 = window.global_position
			var windowSize: Vector2 = window.size
			var mousePos: Vector2 = get_global_mouse_position()
			#if the mouse pointer is inside this window, add the dropped file here
			if(mousePos.x > pos.x && mousePos.x < pos.x+windowSize.x && mousePos.y > pos.y && mousePos.y < pos.y+windowSize.y):
				filepathTo = "%s%s/" % [ResourceManager.GetPathToUserFiles(),filemanager.szFilePath]
				managersWithin.append(filemanager)
				#filemanagerWithin = filemanager

	CopyPasteManager.CopyAllFilesOrFolders(files, filepathTo)
	
		# get_tree().get_first_node_in_group("desktop_file_manager").populate_file_manager()
	#RefreshAllFileManagers()
	for filemanagerWithin: BaseFileManager in managersWithin:
		UtilityHelper.instance.CallOnDelay(0.1, filemanagerWithin.RefreshManager)
