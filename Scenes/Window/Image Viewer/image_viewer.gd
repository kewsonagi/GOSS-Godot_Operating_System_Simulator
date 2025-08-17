extends TextureRect

## The image viewer window.
@export var parentWindow: FakeWindow
var fileName: String
var filePath: String

func _ready() -> void:
	if(parentWindow.creationData.has("Filename")):
		print("image viewer filename: %s" % parentWindow.creationData["Filename"])
		import_image(parentWindow.creationData["Filename"])
		fileName = parentWindow.creationData["Filename"]
		filePath = fileName;
		fileName = fileName.get_file()
		filePath = filePath.get_base_dir()
		
		call_deferred("SetCustomWindowSettings")
		# parentWindow.titleText.text = parentWindow.creationData["Filename"]

func SetCustomWindowSettings() -> void:
	var manifest: AppManifest = parentWindow.creationData["manifest"]
	if(manifest):
		parentWindow.titlebarIcon.icon = manifest.icon
		parentWindow.titleText["theme_override_styles/normal"].bg_color = manifest.colorBGTitle
		parentWindow.transitionsNode["theme_override_styles/panel"].bg_color = manifest.colorBGWindow

func import_image(file_path: String) -> void:
	if !FileAccess.file_exists(file_path):
		NotificationManager.ShowNotification("Error: Cannot find file (was it moved or deleted?)", NotificationManager.E_NOTIFICATION_TYPE.ERROR)
		return
	var image: Image = Image.load_from_file(file_path)
	if(!image):
		image = (ResourceManager.GetResource("Corrupt") as Texture2D).get_image()
	#image.generate_mipmaps()
	#var texture_import: ImageTexture = ImageTexture.create_from_image(image)
	#texture = texture_import
	texture = ImageTexture.create_from_image(image)

func _on_gui_input(event: InputEvent) -> void:
	if(event.is_action_pressed("RightClick")):
		HandleRightClick()

func HandleRightClick() -> void:
	RClickMenuManager.instance.ShowMenu("Image Menu", self)
	RClickMenuManager.instance.AddMenuItem("Set Wallpaper", SetWallpaper)

func SetWallpaper() -> void:
	Wallpaper.wallpaperInstance.apply_wallpaper_from_filename(fileName, filePath)