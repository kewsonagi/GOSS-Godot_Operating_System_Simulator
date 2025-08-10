extends BaseFile
class_name cImageFile

func _ready() -> void:
	super._ready()

func OpenFile() -> void:
	var window: FakeWindow
	
	var windowName:String=szFilePath
	var windowID:String="%s/%s" % [szFilePath, szFileName]
	var windowParent:Node=null#get_tree().current_scene
	var windowData: Dictionary = {}

	var filename: String = szFileName;
	if(!szFilePath.is_empty()):
		filename = "%s/%s" % [szFilePath, szFileName]
	
	windowData["Filename"] = filename;
	window = DefaultValues.spawn_window("res://Scenes/Window/Image Viewer/image_viewer.tscn", windowName, windowID, windowData, windowParent)
	#window.title_text = windowName#%"Folder Title".text
	window.titlebarIcon.icon = fileTexture.texture
	
	DefaultValues.AddWindowToTaskbar(window, fileColor, fileTexture.texture)
	return

func HandleRightClick() -> void:
	super.HandleRightClick()
	RClickMenuManager.instance.AddMenuItem("Set Wallpaper", SetWallpaper)

func SetWallpaper() -> void:
	Wallpaper.wallpaperInstance.apply_wallpaper_from_file(self)
