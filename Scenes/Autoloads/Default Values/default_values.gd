extends Node
## Sets some default values on startup and handles saving/loading user preferences

var wallpaper_name: String
var wallpaper_stretch_mode: TextureRect.StretchMode # int from 0 to 6
@export var background_color_rect: ColorRect# = $"/root/Control/BackgroundColor"
@export var wallpaper: Wallpaper# = $"/root/Control/Wallpaper"
@export var clickHandler: PackedScene = preload("res://Scenes/Autoloads/RClick Menu Manager/ClickHandler.tscn")
#var soundManager2D: AudioStreamPlayer2D
#var soundManager3D: AudioStreamPlayer3D

static var globalSettingsSave: SaveDataBasic
var saveFileName:String = "Global Setting.ini"

func _ready() -> void:
	DisplayServer.window_set_min_size(Vector2i(600, 525))
	
	#saveFileName = UtilityHelper.GetCleanFileString(ResourceManager.GetPathToWindowSettings(), saveFileName, saveFileName.get_extension())
	#globalSettingsSave = UtilityHelper.GetSavefile(ResourceManager.GetPathToWindowSettings(), saveFileName)
	if(!globalSettingsSave):
		globalSettingsSave = SaveDataBasic.new()
	if(!globalSettingsSave.Load(UtilityHelper.GetCleanFileString(ResourceManager.GetPathToWindowSettings(), saveFileName, saveFileName.get_extension()))):
		#setup any defaults
		save_state()
	# if(!IndieBlueprintSaveManager.save_filename_exists(saveFileName)):
	# 	globalSettingsSave = IndieBlueprintSaveManager.create_new_save(saveFileName)
	# else:
	# 	globalSettingsSave = IndieBlueprintSaveManager.load_savegame(saveFileName)
	# 	if(!globalSettingsSave):
	# 		globalSettingsSave = IndieBlueprintSaveManager.create_new_save(saveFileName)
	# 	else:
	# 		load_state()
	load_state()
	save_state()


	
func save_state() -> void:
	if(!globalSettingsSave):return

	globalSettingsSave.data["WallpaperName"] = wallpaper_name
	globalSettingsSave.data["WallpaperStretchMode"] = wallpaper_stretch_mode
	if(background_color_rect):
		globalSettingsSave.data["BackgroundColor"] = background_color_rect.color#.to_html()
	else:
		globalSettingsSave.data["BackgroundColor"] = Color.GRAY
	globalSettingsSave.data["WindowScale"] = get_window().content_scale_factor
	globalSettingsSave.Save()

func load_state() -> void:
	if(!globalSettingsSave.data):return
	
	if(globalSettingsSave.data.has("WallpaperName")):
		wallpaper_name = globalSettingsSave.data["WallpaperName"]
	if(globalSettingsSave.data.has("WallWallpaperStretchModepaperName")):
		wallpaper_stretch_mode = globalSettingsSave.data["WallpaperStretchMode"]
	if(background_color_rect and globalSettingsSave.data.has("BackgroundColor")):
		background_color_rect.color = globalSettingsSave.data["BackgroundColor"]
	if(globalSettingsSave.data.has("WindowScale")):
		get_window().content_scale_factor = globalSettingsSave.data["WindowScale"]
	if (!wallpaper_name.is_empty() and wallpaper):
		wallpaper.apply_wallpaper_from_path(wallpaper_name)
	
	if(wallpaper):
		wallpaper.apply_wallpaper_stretch_mode(wallpaper_stretch_mode)

## Copies the wallpaper to root GodotOS folder so it can load it again later. 
## It doesn't use the actual wallpaper file since it can be removed/deleted.
func save_wallpaperByName(filePath: String, fileName: String) -> void:
	delete_wallpaper()
	
	var from: String = "%s/%s" % [filePath, fileName]
	var to: String = "user://%s" % fileName
	DirAccess.copy_absolute(from, to)
	wallpaper_name = fileName
	save_state()
func save_wallpaper(wallpaper_file: BaseFile) -> void:
	delete_wallpaper()
	
	var from: String = UtilityHelper.GetCleanFileString("%s%s" % [ResourceManager.GetPathToUserFiles(), wallpaper_file.szFilePath], wallpaper_file.szFileName,wallpaper_file.szFileName.get_extension())
	var to: String = ProjectSettings.globalize_path("user://%s" % wallpaper_file.szFileName)
	DirAccess.copy_absolute(from, to)
	wallpaper_name = wallpaper_file.szFileName
	save_state()

func delete_wallpaper() -> void:
	if !wallpaper_name.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://%s" % wallpaper_name))
	wallpaper_name = ""
	save_state()



func AddClickHandler(node: Node) -> HandleClick:
	if(node):
		var handler: HandleClick = clickHandler.instantiate()
		node.add_child(handler)
		node.move_child(handler, 0)
		return handler
	return null
