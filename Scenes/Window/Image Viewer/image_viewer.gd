extends TextureRect

## The image viewer window.
@export var parentWindow: FakeWindow
var fileName: String
var filePath: String

func _ready() -> void:
	if(parentWindow.creationData.has("Filename")):
		import_image(parentWindow.creationData["Filename"])
		fileName = parentWindow.creationData["Filename"]
		filePath = fileName;
		fileName = fileName.get_file()
		filePath = filePath.get_base_dir()
		# parentWindow.titleText.text = parentWindow.creationData["Filename"]


func import_image(file_path: String) -> void:
	if !FileAccess.file_exists("user://files/%s" % file_path):
		NotificationManager.ShowNotification("Error: Cannot find file (was it moved or deleted?)", NotificationManager.E_NOTIFICATION_TYPE.ERROR)
		return
	var image: Image = Image.load_from_file("user://files/%s" % file_path)
	image.generate_mipmaps()
	var texture_import: ImageTexture = ImageTexture.create_from_image(image)
	texture = texture_import

func _on_gui_input(event: InputEvent) -> void:
	if(event.is_action_pressed("RightClick")):
		HandleRightClick()

func HandleRightClick() -> void:
	RClickMenuManager.instance.ShowMenu("Image Menu", self)
	RClickMenuManager.instance.AddMenuItem("Set Wallpaper", SetWallpaper)

func SetWallpaper() -> void:
	Wallpaper.wallpaperInstance.apply_wallpaper_from_filename(fileName, filePath)