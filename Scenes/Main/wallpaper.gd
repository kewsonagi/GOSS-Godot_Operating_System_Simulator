extends TextureRect
class_name Wallpaper

## The desktop wallpaper, has an empty texture when the wallpaper is removed.
@export var backgroundColor: ColorRect
@export var dummyTexture: Texture2D
signal wallpaper_added()
static var wallpaperInstance: Wallpaper

func _ready() -> void:
	wallpaperInstance = self;
	# I use a node to fade because fading modulate doesn't work if there is no texture
	#$Fade.modulate.a = 0
	#$Fade.visible = true
	
	if(backgroundColor):
		DefaultValues.background_color_rect = backgroundColor
		DefaultValues.wallpaper = self
	
	DefaultValues.load_state()

## Applies wallpaper from path (called from default_values.gd on start)
func apply_wallpaper_from_path(path: String) -> void:
	wallpaper_added.emit()
	
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path("user://%s" % path))
	if(image):
		add_wallpaper(image)

## Applies wallpaper from an image file
func apply_wallpaper_from_file(image_file: BaseFile) -> void:
	var filepath:String = UtilityHelper.GetCleanFileString("%s/%s" % [ResourceManager.GetPathToUserFiles().get_base_dir(),image_file.szFilePath], image_file.szFileName, image_file.szFileName.get_extension())
	if(!FileAccess.file_exists(filepath)):return

	wallpaper_added.emit()
	DefaultValues.save_wallpaper(image_file)
	
	var image: Image = Image.load_from_file(filepath)
	if(image):
		add_wallpaper(image)
func apply_wallpaper_from_filename(fileName: String, filePath: String) -> void:
	var fullFilepath:String = "%s/%s" % [filePath, fileName]
	if(!FileAccess.file_exists(fullFilepath)):return
	
	wallpaper_added.emit()
	DefaultValues.save_wallpaperByName(filePath, fileName)
	
	var image: Image = Image.load_from_file(fullFilepath)
	add_wallpaper(image)

func add_wallpaper(image: Image) -> void:
	image.generate_mipmaps()
	var texture_import: ImageTexture = ImageTexture.create_from_image(image)
	
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	#await tween.tween_property(self, "self_modulate:a", 0.5, 0.5).finished
	
	texture = texture_import
	
	tween.tween_property(self, "self_modulate:a", 1, 0.5)

func remove_wallpaper() -> void:
	DefaultValues.delete_wallpaper()
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	#await tween.tween_property(self, "self_modulate:a", 0.5, 0.5).finished
	tween.tween_property(self, "self_modulate:a", 0, 0.5)
	
	texture = null
	texture = dummyTexture#.duplicate()
	

func apply_wallpaper_stretch_mode(new_stretch_mode: TextureRect.StretchMode) -> void:
	stretch_mode = new_stretch_mode
	DefaultValues.wallpaper_stretch_mode = stretch_mode
	DefaultValues.save_state()
