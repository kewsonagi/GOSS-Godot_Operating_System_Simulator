extends Node
## Sets some default values on startup and handles saving/loading user preferences

var wallpaper_name: String
var wallpaper_stretch_mode: TextureRect.StretchMode # int from 0 to 6
@onready var background_color_rect: ColorRect = $"/root/Control/BackgroundColor"
@onready var wallpaper: Wallpaper = $"/root/Control/Wallpaper"
#var soundManager2D: AudioStreamPlayer2D
#var soundManager3D: AudioStreamPlayer3D
static var windows: Array[FakeWindow] = []
static var globalSettingsSave: IndieBlueprintSavedGame
var saveFileName:String = "Global Settings"

func _ready() -> void:
	DisplayServer.window_set_min_size(Vector2i(600, 525))
	
	saveFileName = IndieBlueprintSavedGame.clean_filename(saveFileName)
	if(!IndieBlueprintSaveManager.save_filename_exists(saveFileName)):
		globalSettingsSave = IndieBlueprintSaveManager.create_new_save(saveFileName)
	else:
		globalSettingsSave = IndieBlueprintSaveManager.load_savegame(saveFileName)
		if(!globalSettingsSave):
			globalSettingsSave = IndieBlueprintSaveManager.create_new_save(saveFileName)
		else:
			load_state()

	save_state()

func save_state() -> void:
	globalSettingsSave.data["WallpaperName"] = wallpaper_name
	globalSettingsSave.data["WallpaperStretchMode"] = wallpaper_stretch_mode
	if(background_color_rect):
		globalSettingsSave.data["BackgroundColor"] = background_color_rect.color#.to_html()
	else:
		globalSettingsSave.data["BackgroundColor"] = Color.GRAY
	globalSettingsSave.data["WindowScale"] = get_window().content_scale_factor
	globalSettingsSave.write_savegame()

func load_state() -> void:
	wallpaper_name = globalSettingsSave.data["WallpaperName"]
	wallpaper_stretch_mode = globalSettingsSave.data["WallpaperStretchMode"]
	if(background_color_rect):
		background_color_rect.color = globalSettingsSave.data["BackgroundColor"]
		print("loading defaults\nwallpaper name: %s\nbackground color: %s" % [wallpaper_name, background_color_rect.color])
	get_window().content_scale_factor = globalSettingsSave.data["WindowScale"]
	if (!wallpaper_name.is_empty() and wallpaper):
		wallpaper.apply_wallpaper_from_path(wallpaper_name)
	
	if(wallpaper):
		wallpaper.apply_wallpaper_stretch_mode(wallpaper_stretch_mode)

## Copies the wallpaper to root GodotOS folder so it can load it again later. 
## It doesn't use the actual wallpaper file since it can be removed/deleted.
func save_wallpaperByName(filePath: String, fileName: String) -> void:
	delete_wallpaper()
	
	var from: String = "user://files/%s/%s" % [filePath, fileName]
	var to: String = "user://%s" % fileName
	DirAccess.copy_absolute(from, to)
	wallpaper_name = fileName
	save_state()
func save_wallpaper(wallpaper_file: BaseFile) -> void:
	delete_wallpaper()
	
	var from: String = "user://files/%s/%s" % [wallpaper_file.szFilePath, wallpaper_file.szFileName]
	var to: String = "user://%s" % wallpaper_file.szFileName
	DirAccess.copy_absolute(from, to)
	wallpaper_name = wallpaper_file.szFileName
	save_state()

func delete_wallpaper() -> void:
	if !wallpaper_name.is_empty():
		DirAccess.remove_absolute("user://%s" % wallpaper_name)
	wallpaper_name = ""
	save_state()

func spawn_window(sceneToLoadInsideWindow: String, windowName: String = "Untitled", windowID: String ="game", data: Dictionary = {}, parentWindow: Node = null) -> Node:
	#print("spawning new window: ", sceneToLoadInsideWindow)
	var window: FakeWindow
	window = ResourceLoader.load(sceneToLoadInsideWindow).instantiate()
	#print("default values, spawn_window: %s" % (window as Node))
	
	window.title_text = windowName;
	window.SetID(windowID)
	window.SetData(data)
	if(parentWindow):
		parentWindow.add_child(window)
	else:
		get_tree().current_scene.add_child(window)
	
	windows.append(window)
	window.deleted.connect(CloseWindow)
		
	return window as Node

func spawn_game_window(sceneToLoadInsideWindow: String, windowName: String = "Untitled", windowID: String ="game", data: Dictionary = {}, parentWindow: Node = null) -> Node:
	print("spawning new window: ", sceneToLoadInsideWindow)
	#var boot: BootGame = load("res://Scenes/Window/Game Window/game_window.tscn").instantiate()
	var window: FakeWindow
	window = ResourceLoader.load("res://Scenes/Window/Game Window/game_window.tscn").instantiate()
	var gameWindowNode: Node = window.get_node("%Game Window")
	var gameBootloader: Node = ResourceLoader.load(sceneToLoadInsideWindow).instantiate()
	if(gameBootloader is BootGame):
		gameWindowNode.add_child(gameBootloader)
		(gameBootloader as BootGame).StartGame()
		if((gameBootloader as BootGame).spawnedWindow):
			gameWindowNode.add_child((gameBootloader as BootGame).spawnedWindow)

		#gameBootloader.queue_free()
	else:
		gameWindowNode.add_child(gameBootloader)
	
	window.title_text = windowName;
	window.SetID(windowID)
	window.SetData(data)
	if(parentWindow):
		parentWindow.add_child(window)
	else:
		get_tree().current_scene.add_child(window)
	
	windows.append(window)
	window.deleted.connect(CloseWindow)

	return window as Node

func AddWindowToTaskbar(window: FakeWindow, color: Color = Color.GRAY, texture: Texture2D=null) -> void:
	#add window to taskbar
	var taskbar_button: Control = ResourceLoader.load("res://Scenes/Taskbar/taskbar_button.tscn").instantiate()
	taskbar_button.target_window = window
	if(texture):
		taskbar_button.get_node("TextureMargin/TextureRect").texture = texture
	taskbar_button.active_color = color
	get_tree().get_first_node_in_group("taskbar_buttons").add_child(taskbar_button)

func CloseWindow(window: FakeWindow) -> void:
	windows.erase(window)
	
func _exit_tree() -> void:
	windows.clear()
