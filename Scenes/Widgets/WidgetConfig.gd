extends Resource

class_name  WidgetConfig
const WIDGET_EXT = "tres"

@export var key: String = "nameID"
@export var name: String = "widget name"
@export var description: String = "widget description"
@export var path: String = "res://Widgets/widget.tscn"
@export var icon: Texture2D = preload("res://Art/shaded/15-file-empty.png")
@export var resizable: bool = true
@export var category: String = "General"

func _init() -> void:
    key = "nameID"
    name = "awidgetpp name"
    description = "widget description"
    path = "res://Widgets/widget.tscn"
    icon = preload("res://Art/shaded/15-file-empty.png")
    resizable = true
    category = "General"

func SaveConfig(filepath: String, filename: String) -> void:
    var realPath: String = UtilityHelper.GetCleanFileString(filepath, filename, WIDGET_EXT)
    if(!realPath.is_empty() and realPath.is_valid_filename()):
        DirAccess.make_dir_recursive_absolute(path.get_base_dir())
        ResourceSaver.save(self, realPath)