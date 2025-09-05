extends Node

class_name UtilityHelper

enum LOG_LEVEL{Debug,Info,Warning,Error}
static var instance: UtilityHelper

func _ready() -> void:
	if(!instance):
		instance = self

static func CallOnTimer(f: float, c: Callable, caller: Node) -> void:
	caller.get_tree().create_timer(f).timeout.connect(c)

static func Log(s:String, level: LOG_LEVEL=LOG_LEVEL.Debug) -> void:
	if(level == LOG_LEVEL.Debug):
		print(s)
	elif(level == LOG_LEVEL.Info):
		print(s)
	elif(level == LOG_LEVEL.Warning):
		print(s)
	elif(level == LOG_LEVEL.Error):
		print(s)

static func AddInputHandler(node: Node) -> HandleClick:
	if(node):
		var handler: HandleClick = HandleClick.new()
		node.add_child(handler)
		node.move_child(handler, 0)
		handler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		handler.size_flags_vertical = Control.SIZE_EXPAND_FILL
		handler.set_anchors_preset(Control.PRESET_FULL_RECT)
		return handler
	return null

static func GetCleanFileString(filepath: String, filename: String, extension: String) -> String:
	if(!extension.get_extension().is_empty()):
		extension = extension.get_extension()
	else:
		extension = extension.get_file().get_basename()

	if(!filepath.get_extension().is_empty() or filepath.ends_with("/")):
		filepath = filepath.get_base_dir()

	if(!filename.get_file().is_empty()):
		filename = filename.get_file()
	if(!filename.get_extension().is_empty()):
		filename = filename.get_basename()

	return ProjectSettings.globalize_path("%s/%s.%s" % [filepath,filename,extension])

static func GetCleanFilePath(filepath: String) -> String:
	return GetCleanFileString(filepath.get_base_dir(), filepath.get_file(), filepath.get_file().get_extension())

static func MakeFileString(filepath: String, filename: String, extension: String) -> String:
	return GetCleanFileString(filepath, filename, extension)

static func GetFirstFreeFileName(filepath: String, filename: String) -> String:
	var newFilename: String = filename.get_file().get_basename()
	if DirAccess.dir_exists_absolute("%s/%s.%s" % [filepath.get_base_dir(), newFilename, filename.get_extension()]):
		for i in range(1, 1000):
			newFilename = "%s(%s)" % [filename.get_file().get_basename(),i]
			if !DirAccess.dir_exists_absolute("%s/%s.%s" % [filepath.get_base_dir(), newFilename, filename.get_extension()]):
				break
	return "%s.%s" % [newFilename,filename.get_extension()]

static func GetFirstFreeFolderName(filepath: String, foldername: String) -> String:
	var newFoldername: String = foldername
	if DirAccess.dir_exists_absolute("%s/%s" % [filepath.get_base_dir(), newFoldername]):
		for i in range(1, 1000):
			newFoldername = "%s_%s" % [foldername,i]
			if !DirAccess.dir_exists_absolute("%s/%s" % [filepath.get_base_dir(), newFoldername]):
				break
	return newFoldername

static func CreateFolder(filepath: String, foldername: String) -> bool:
	if(DirAccess.dir_exists_absolute(filepath.get_base_dir()) and !DirAccess.dir_exists_absolute("%s/%s" % [filepath.get_base_dir(), foldername])):
		DirAccess.make_dir_recursive_absolute("%s/%s" % [filepath, foldername])
		return true
	return false

static func CreateFile(filepath: String, filename: String) -> bool:
	if(DirAccess.dir_exists_absolute(filepath.get_base_dir()) and !FileAccess.file_exists("%s/%s" % [filepath.get_base_dir(), filename])):
		var _file: FileAccess = FileAccess.open("%s/%s" % [filepath, filename], FileAccess.WRITE)
		if(_file):
			return true
	return false

static func GetSavefile(filepath: String, filename: String) -> SaveDataBasic:
	var save: SaveDataBasic = SaveDataBasic.new()
	save.Load(UtilityHelper.GetCleanFileString(filepath, filename, filename))
	return save

static func GetScreenRect() -> Rect2:
	return Desktop.desktopFullscreen
static func GetDesktopRect() -> Rect2:
	return Desktop.desktopRect

static func GlobalizePath(s: String) -> String:
	if(s.begins_with("res://")):
		if OS.has_feature("editor"):
			return ProjectSettings.globalize_path(s)
		else:
			s = s.replace("res://", "")
			return OS.get_executable_path().get_base_dir().path_join(s)

	
	return ProjectSettings.globalize_path(s)
	
func CallOnDelay(f: float, c: Callable) -> void:
	get_tree().create_timer(f).timeout.connect(c)

static func CopyFile(from: String, to: String, override: bool=false) -> void:
	if(!override and FileAccess.file_exists(to)):return

	var fromFile: FileAccess = FileAccess.open(from, FileAccess.READ)
	var toFile: FileAccess = FileAccess.open(to, FileAccess.WRITE)
	toFile.store_buffer(fromFile.get_buffer(fromFile.get_length()))
	
	fromFile.close()
	toFile.close()